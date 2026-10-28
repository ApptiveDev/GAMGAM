package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.entity.AppointmentParticipant;
import com.gamgam.backend.appointment.repository.AppointmentParticipantRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.entity.AppointmentVote;
import com.gamgam.backend.appointment.repository.AppointmentVoteRepository;
import com.gamgam.backend.appointment.vo.VoteType;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.global.util.KstTimeConverter;
import com.gamgam.backend.room.RoomAccess;
import java.util.List;
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
        synchronizeParticipation(appointment, userId);
        return response(appointment, userId);
    }

    private void synchronizeParticipation(Appointment appointment, String userId) {
        var participant = participants.findByAppointmentIdAndUserId(appointment.getId(), userId);
        boolean hasVotes = votes.existsByAppointmentIdAndUserId(appointment.getId(), userId);
        if (hasVotes && participant.isEmpty()) {
            participants.save(new AppointmentParticipant(appointment, userId));
        } else if (!hasVotes) {
            participant.ifPresent(participants::delete);
        }
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
