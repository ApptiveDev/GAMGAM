package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.dto.TimeCandidateRequest;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PlaceRequest;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.entity.AppointmentParticipant;
import com.gamgam.backend.appointment.repository.AppointmentParticipantRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.appointment.entity.AppointmentVote;
import com.gamgam.backend.appointment.repository.AppointmentVoteRepository;
import com.gamgam.backend.appointment.vo.VoteType;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.global.util.KstTimeConverter;
import com.gamgam.backend.room.RoomAccess;
import java.util.List;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.Objects;
import java.util.Set;
import java.util.TreeSet;
import java.util.stream.IntStream;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AppointmentVotingService {
    private final AppointmentRepository appointments;
    private final AppointmentVoteRepository votes;
    private final AppointmentParticipantRepository participants;
    private final RoomAccess rooms;

    public AppointmentVotingResponse get(String id, String userId) {
        return response(load(id, userId, false), userId);
    }

    @Transactional
    public AppointmentVotingResponse voteTime(String id, String userId, Set<Integer> indexes) {
        return vote(id, userId, indexes, VoteType.TIME);
    }

    @Transactional
    public AppointmentVotingResponse votePlace(String id, String userId, Set<Integer> indexes) {
        return vote(id, userId, indexes, VoteType.PLACE);
    }

    private AppointmentVotingResponse vote(String id, String userId, Set<Integer> indexes, VoteType type) {
        Appointment appointment = load(id, userId, true);
        requireCoordinating(appointment);
        boolean allowed = type == VoteType.TIME
                ? appointment.getTemplate().coordinatesTime() : appointment.getTemplate().coordinatesPlace();
        if (!allowed) throw new BusinessException(ErrorCode.VOTE_NOT_ALLOWED);
        int size = type == VoteType.TIME ? appointment.getCandidatesTime().size() : appointment.getCandidatesPlace().size();
        if (indexes == null || indexes.stream().anyMatch(i -> i == null || i < 0 || i >= size)) {
            throw new BusinessException(ErrorCode.INVALID_OPTION);
        }
        // 범위 확인을 먼저 해서 잘못된 요청이 기존 표를 지우지 않도록 한다.
        votes.deleteSelection(id, userId, type);
        votes.saveAll(new TreeSet<>(indexes).stream()
                .map(index -> new AppointmentVote(appointment, userId, type, index)).toList());
        synchronizeParticipation(appointment, userId, indexes.isEmpty() ? null : false);
        return response(appointment, userId);
    }

    @Transactional
    public AppointmentVotingResponse participateRegardless(String id, String userId, boolean selected) {
        Appointment appointment = load(id, userId, true);
        requireCoordinating(appointment);
        if (selected) {
            // 특정 후보 선택과 배타적이다. 전환과 참여자 갱신을 하나의 트랜잭션에서 처리한다.
            votes.deleteSelection(id, userId, VoteType.TIME);
            votes.deleteSelection(id, userId, VoteType.PLACE);
        }
        synchronizeParticipation(appointment, userId, selected);
        return response(appointment, userId);
    }

    private void synchronizeParticipation(Appointment appointment, String userId, Boolean regardless) {
        var participant = participants.findByAppointmentIdAndUserId(appointment.getId(), userId)
                .orElseGet(() -> new AppointmentParticipant(appointment, userId));
        if (regardless != null) participant.setRegardlessOfTimeAndPlace(regardless);
        if (participant.isRegardlessOfTimeAndPlace()
                || votes.existsByAppointmentIdAndUserId(appointment.getId(), userId)) {
            if (participant.getId() == null) participants.save(participant);
        } else if (participant.getId() != null) {
            participants.delete(participant);
        }
    }

    @Transactional
    public AppointmentVotingResponse addTimeCandidate(String id, String userId, TimeCandidateRequest request) {
        Appointment appointment = load(id, userId, true);
        requireCoordinating(appointment);
        if (!appointment.getTemplate().coordinatesTime()) {
            throw new BusinessException(ErrorCode.VOTE_NOT_ALLOWED);
        }
        if (request.time() == null || !request.time().isAfter(OffsetDateTime.now())) {
            throw new BusinessException(ErrorCode.BAD_REQUEST);
        }
        var time = normalizeCandidateTime(request.time());
        // 오프셋 표기가 달라도 같은 순간이면 중복 후보로 처리한다.
        boolean duplicate = appointment.getCandidatesTime().stream()
                .anyMatch(candidate -> normalizeCandidateTime(candidate).isEqual(time));
        if (duplicate) throw new BusinessException(ErrorCode.DUPLICATE_CANDIDATE);
        appointment.addCandidateTime(time);
        return response(appointment, userId);
    }

    private static OffsetDateTime normalizeCandidateTime(OffsetDateTime time) {
        // DB의 timestamp(6) 정밀도에 맞춰 반올림해 재요청 시에도 같은 후보로 인식한다.
        return KstTimeConverter.toUtc(time).plusNanos(500).truncatedTo(ChronoUnit.MICROS);
    }

    @Transactional
    public AppointmentVotingResponse addPlaceCandidate(String id, String userId, PlaceRequest request) {
        Appointment appointment = load(id, userId, true);
        requireCoordinating(appointment);
        if (!appointment.getTemplate().coordinatesPlace()) {
            throw new BusinessException(ErrorCode.VOTE_NOT_ALLOWED);
        }
        String name = request.name().strip();
        boolean duplicate = appointment.getCandidatesPlace().stream().anyMatch(place ->
                name.equalsIgnoreCase(place.name().strip())
                        && Objects.equals(request.latitude(), place.latitude())
                        && Objects.equals(request.longitude(), place.longitude()));
        if (duplicate) throw new BusinessException(ErrorCode.DUPLICATE_CANDIDATE);
        appointment.addCandidatePlace(new Place(name, request.latitude(), request.longitude()));
        // 제안만으로 투표나 참여 신청을 만들지 않는다. 기존 투표도 그대로 유지한다.
        return response(appointment, userId);
    }

    private Appointment load(String id, String userId, boolean forUpdate) {
        Appointment appointment = (forUpdate ? appointments.findByIdForUpdate(id) : appointments.findById(id))
                .orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
        rooms.requireMember(appointment.getRoomId(), userId);
        return appointment;
    }

    private static void requireCoordinating(Appointment appointment) {
        if (appointment.getStatus() != AppointmentStatus.COORDINATING) {
            throw new BusinessException(ErrorCode.NOT_COORDINATING);
        }
    }

    private AppointmentVotingResponse response(Appointment appointment, String userId) {
        List<AppointmentVote> allVotes = votes.findByAppointmentIdOrderByIdAsc(appointment.getId());
        var members = participants.findByAppointmentIdOrderByJoinedAtAscIdAsc(appointment.getId());
        var participantIds = members.stream().map(AppointmentParticipant::getUserId).toList();
        var regardlessIds = members.stream().filter(AppointmentParticipant::isRegardlessOfTimeAndPlace)
                .map(AppointmentParticipant::getUserId).toList();
        var times = IntStream.range(0, appointment.getCandidatesTime().size()).mapToObj(index -> {
            var voterIds = voterIds(allVotes, VoteType.TIME, index);
            return new AppointmentVotingResponse.TimeOption(index,
                    KstTimeConverter.toKst(appointment.getCandidatesTime().get(index)),
                    voterIds.size(), voterIds, voterIds.contains(userId));
        }).toList();
        var places = IntStream.range(0, appointment.getCandidatesPlace().size()).mapToObj(index -> {
            var voterIds = voterIds(allVotes, VoteType.PLACE, index);
            return new AppointmentVotingResponse.PlaceOption(index, appointment.getCandidatesPlace().get(index),
                    voterIds.size(), voterIds, voterIds.contains(userId));
        }).toList();
        return new AppointmentVotingResponse(appointment.getId(), appointment.getRoomId(), appointment.getStatus(),
                participantIds.contains(userId), participantIds, regardlessIds.contains(userId), regardlessIds, times, places);
    }

    private static List<String> voterIds(List<AppointmentVote> votes, VoteType type, int index) {
        return votes.stream().filter(v -> v.getType() == type && v.getOptionIndex() == index)
                .map(AppointmentVote::getUserId).sorted().toList();
    }
}
