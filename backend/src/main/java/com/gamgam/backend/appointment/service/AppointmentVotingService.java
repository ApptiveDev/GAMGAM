package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PlaceRequest;
import com.gamgam.backend.appointment.dto.TimeCandidateRequest;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.entity.AppointmentParticipant;
import com.gamgam.backend.appointment.entity.AppointmentPlaceVote;
import com.gamgam.backend.appointment.entity.AppointmentTimeVote;
import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentParticipantRepository;
import com.gamgam.backend.appointment.repository.AppointmentPlaceVoteRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.repository.AppointmentTimeVoteRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.global.util.KstTimeConverter;
import java.time.OffsetDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
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
    private final AppointmentMemberRepository members;
    private final AppointmentTimeVoteRepository timeVotes;
    private final AppointmentPlaceVoteRepository placeVotes;
    private final AppointmentParticipantRepository participants;

    public AppointmentVotingResponse get(String id, String userId) {
        return response(load(id, userId, false), userId);
    }

    @Transactional
    public AppointmentVotingResponse voteTime(String id, String userId, Set<Integer> indexes) {
        Appointment appointment = load(id, userId, true);
        requireVoteAllowed(appointment, true);
        validateIndexes(indexes, appointment.getCandidatesTime().size());
        timeVotes.deleteAllByAppointmentIdAndUserId(id, userId);
        timeVotes.flush();
        timeVotes.saveAll(new TreeSet<>(indexes).stream()
                .map(index -> new AppointmentTimeVote(id, userId, index)).toList());
        synchronizeParticipation(appointment, userId, indexes.isEmpty() ? null : false);
        return response(appointment, userId);
    }

    @Transactional
    public AppointmentVotingResponse votePlace(String id, String userId, Set<Integer> indexes) {
        Appointment appointment = load(id, userId, true);
        requireVoteAllowed(appointment, false);
        validateIndexes(indexes, appointment.getCandidatesPlace().size());
        placeVotes.deleteAllByAppointmentIdAndUserId(id, userId);
        placeVotes.flush();
        placeVotes.saveAll(new TreeSet<>(indexes).stream()
                .map(index -> new AppointmentPlaceVote(id, userId, index)).toList());
        synchronizeParticipation(appointment, userId, indexes.isEmpty() ? null : false);
        return response(appointment, userId);
    }

    @Transactional
    public AppointmentVotingResponse participateRegardless(String id, String userId, boolean selected) {
        Appointment appointment = load(id, userId, true);
        requireCoordinating(appointment);
        if (selected) {
            timeVotes.deleteAllByAppointmentIdAndUserId(id, userId);
            placeVotes.deleteAllByAppointmentIdAndUserId(id, userId);
            timeVotes.flush();
            placeVotes.flush();
        }
        synchronizeParticipation(appointment, userId, selected);
        return response(appointment, userId);
    }

    @Transactional
    public AppointmentVotingResponse addTimeCandidate(String id, String userId, TimeCandidateRequest request) {
        Appointment appointment = load(id, userId, true);
        requireVoteAllowed(appointment, true);
        OffsetDateTime time = normalizeCandidateTime(request.time());
        boolean duplicate = appointment.getCandidatesTime().stream()
                .anyMatch(candidate -> normalizeCandidateTime(candidate).isEqual(time));
        if (duplicate) throw new BusinessException(ErrorCode.DUPLICATE_CANDIDATE);
        appointment.addCandidateTime(time);
        return response(appointment, userId);
    }

    @Transactional
    public AppointmentVotingResponse addPlaceCandidate(String id, String userId, PlaceRequest request) {
        Appointment appointment = load(id, userId, true);
        requireVoteAllowed(appointment, false);
        String name = request.name().strip();
        boolean duplicate = appointment.getCandidatesPlace().stream().anyMatch(place ->
                name.equalsIgnoreCase(place.name().strip())
                        && Objects.equals(request.latitude(), place.latitude())
                        && Objects.equals(request.longitude(), place.longitude()));
        if (duplicate) throw new BusinessException(ErrorCode.DUPLICATE_CANDIDATE);
        appointment.addCandidatePlace(new Place(name, request.latitude(), request.longitude()));
        return response(appointment, userId);
    }

    private Appointment load(String id, String userId, boolean forUpdate) {
        Appointment appointment = (forUpdate ? appointments.findByIdForUpdate(id) : appointments.findById(id))
                .orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
        if (!members.existsByAppointmentIdAndUserId(id, userId)) {
            throw new BusinessException(ErrorCode.APPOINTMENT_ACCESS_DENIED);
        }
        return appointment;
    }

    private static void requireVoteAllowed(Appointment appointment, boolean time) {
        requireCoordinating(appointment);
        boolean allowed = time ? appointment.getTemplate().coordinatesTime()
                : appointment.getTemplate().coordinatesPlace();
        if (!allowed) throw new BusinessException(ErrorCode.VOTE_NOT_ALLOWED);
    }

    private static void requireCoordinating(Appointment appointment) {
        if (appointment.getStatus() != AppointmentStatus.COORDINATING) {
            throw new BusinessException(ErrorCode.NOT_COORDINATING);
        }
    }

    private static void validateIndexes(Set<Integer> indexes, int size) {
        if (indexes == null || indexes.stream().anyMatch(index -> index == null || index < 0 || index >= size)) {
            throw new BusinessException(ErrorCode.INVALID_OPTION);
        }
    }

    private static OffsetDateTime normalizeCandidateTime(OffsetDateTime time) {
        if (time == null || !time.isAfter(OffsetDateTime.now())) {
            throw new BusinessException(ErrorCode.BAD_REQUEST);
        }
        return KstTimeConverter.toUtc(time).plusNanos(500).truncatedTo(ChronoUnit.MICROS);
    }

    private void synchronizeParticipation(Appointment appointment, String userId, Boolean regardless) {
        AppointmentParticipant participant = participants.findByAppointmentIdAndUserId(appointment.getId(), userId)
                .orElseGet(() -> new AppointmentParticipant(appointment, userId));
        if (regardless != null) participant.setRegardlessOfTimeAndPlace(regardless);
        boolean hasVote = timeVotes.existsByAppointmentIdAndUserId(appointment.getId(), userId)
                || placeVotes.existsByAppointmentIdAndUserId(appointment.getId(), userId);
        if (participant.isRegardlessOfTimeAndPlace() || hasVote) {
            if (participant.getId() == null) participants.save(participant);
        } else if (participant.getId() != null) {
            participants.delete(participant);
        }
    }

    private AppointmentVotingResponse response(Appointment appointment, String userId) {
        List<AppointmentTimeVote> allTimeVotes = timeVotes.findAllByAppointmentId(appointment.getId());
        List<AppointmentPlaceVote> allPlaceVotes = placeVotes.findAllByAppointmentId(appointment.getId());
        List<AppointmentParticipant> allParticipants =
                participants.findByAppointmentIdOrderByJoinedAtAscIdAsc(appointment.getId());
        List<String> participantIds = allParticipants.stream().map(AppointmentParticipant::getUserId).toList();
        List<String> regardlessIds = allParticipants.stream()
                .filter(AppointmentParticipant::isRegardlessOfTimeAndPlace)
                .map(AppointmentParticipant::getUserId).toList();
        var times = IntStream.range(0, appointment.getCandidatesTime().size()).mapToObj(index -> {
            List<String> voterIds = allTimeVotes.stream().filter(vote -> vote.getOptionIndex() == index)
                    .map(AppointmentTimeVote::getUserId).sorted().toList();
            return new AppointmentVotingResponse.TimeOption(index,
                    KstTimeConverter.toKst(appointment.getCandidatesTime().get(index)),
                    voterIds.size(), voterIds, voterIds.contains(userId));
        }).toList();
        var places = IntStream.range(0, appointment.getCandidatesPlace().size()).mapToObj(index -> {
            List<String> voterIds = allPlaceVotes.stream().filter(vote -> vote.getOptionIndex() == index)
                    .map(AppointmentPlaceVote::getUserId).sorted().toList();
            return new AppointmentVotingResponse.PlaceOption(index, appointment.getCandidatesPlace().get(index),
                    voterIds.size(), voterIds, voterIds.contains(userId));
        }).toList();
        return new AppointmentVotingResponse(appointment.getId(), appointment.getRoomId(), appointment.getStatus(),
                participantIds.contains(userId), participantIds, regardlessIds.contains(userId), regardlessIds,
                times, places);
    }
}
