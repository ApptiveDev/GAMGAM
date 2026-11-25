package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.*;
import com.gamgam.backend.appointment.entity.*;
import com.gamgam.backend.appointment.repository.*;
import com.gamgam.backend.appointment.vo.*;
import com.gamgam.backend.global.exception.*;
import com.gamgam.backend.global.util.KstTimeConverter;
import com.gamgam.backend.room.RoomAccess;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional
public class PollManagementService {
    private final AppointmentRepository appointments;
    private final AppointmentVoteRepository votes;
    private final AppointmentMemberRepository members;
    private final AppointmentParticipationService participation;
    private final AppointmentVotingService voting;
    private final RoomAccess rooms;
    private final com.gamgam.backend.media.MediaService media;

    public AppointmentVotingResponse configure(String id, String user, VoteType type, PollSettingsRequest r) {
        Appointment a = host(id, user);
        editable(a, type);
        if (votes.findByAppointmentIdOrderByIdAsc(id).stream().anyMatch(v -> v.getType() == type))
            throw new BusinessException(ErrorCode.POLL_HAS_VOTES);
        a.mutablePoll(type).configure(r.multipleSelection(), r.anonymous(), r.allowAddingOptions(),
                r.durationMinutes(), r.giftDescription(), r.giftMethod(), r.winnerCount());
        return voting.get(id, user);
    }

    public AppointmentVotingResponse close(String id, String user, VoteType type) {
        Appointment a = host(id, user);
        coordinating(a, type);
        a.mutablePoll(type).close();
        return voting.get(id, user);
    }

    public AppointmentVotingResponse award(String id, String user, VoteType type) {
        Appointment a = host(id, user);
        PollSettings p = a.mutablePoll(type);
        boolean confirmed = type == VoteType.TIME ? a.getConfirmedTime() != null : a.getConfirmedPlace() != null;
        if ((!p.closed() && !confirmed) || p.getGiftMethod() == null) throw new BusinessException(ErrorCode.BAD_REQUEST);
        if (p.getWinnerIds() == null) {
            // Current voters in first surviving ballot order. A cancelled ballot forfeits priority.
            var eligible = new ArrayList<>(votes.findByAppointmentIdOrderByIdAsc(id).stream()
                    .filter(v -> v.getType() == type).map(AppointmentVote::getUserId).distinct().toList());
            if (p.getGiftMethod() == PollSettings.GiftMethod.RANDOM) Collections.shuffle(eligible, new java.security.SecureRandom());
            p.award(eligible.subList(0, Math.min(eligible.size(), p.getWinnerCount())));
        }
        return voting.get(id, user);
    }

    public AppointmentVotingResponse editTime(String id, String user, String candidate, TimeCandidateRequest r) {
        Appointment a = host(id, user); editable(a, VoteType.TIME);
        var option = a.getCandidatesTime().stream().filter(c -> c.getCandidateId().equals(candidate)).findFirst()
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_OPTION));
        var time = KstTimeConverter.toUtc(r.time()).plusNanos(500).truncatedTo(java.time.temporal.ChronoUnit.MICROS);
        if (a.getCandidatesTime().stream().anyMatch(c -> !c.getCandidateId().equals(candidate) && c.getTime().isEqual(time)))
            throw new BusinessException(ErrorCode.DUPLICATE_CANDIDATE);
        if (option.getTime().isEqual(time)) return voting.get(id, user);
        option.change(time); clearCandidate(a, VoteType.TIME, candidate);
        return voting.get(id, user);
    }

    public AppointmentVotingResponse editPlace(String id, String user, String candidate, CreateAppointmentRequest.PlaceRequest r) {
        Appointment a = host(id, user); editable(a, VoteType.PLACE);
        var option = a.getCandidatesPlace().stream().filter(c -> c.getCandidateId().equals(candidate)).findFirst()
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_OPTION));
        if (a.getCandidatesPlace().stream().anyMatch(c -> !c.getCandidateId().equals(candidate)
                && c.getPlace().name().strip().equalsIgnoreCase(r.name().strip())
                && Objects.equals(c.getPlace().latitude(), r.latitude()) && Objects.equals(c.getPlace().longitude(), r.longitude())))
            throw new BusinessException(ErrorCode.DUPLICATE_CANDIDATE);
        if (option.getPlace().equals(r.toDomain())) return voting.get(id, user);
        media.validateReference(user, r.imageUrl());
        option.change(r.toDomain()); clearCandidate(a, VoteType.PLACE, candidate);
        return voting.get(id, user);
    }

    public AppointmentVotingResponse delete(String id, String user, VoteType type, String candidate) {
        Appointment a = host(id, user); editable(a, type);
        boolean removed = type == VoteType.TIME
                ? a.getCandidatesTime().removeIf(c -> c.getCandidateId().equals(candidate))
                : a.getCandidatesPlace().removeIf(c -> c.getCandidateId().equals(candidate));
        if (!removed) throw new BusinessException(ErrorCode.INVALID_OPTION);
        clearCandidate(a, type, candidate);
        return voting.get(id, user);
    }

    private void clearCandidate(Appointment a, VoteType type, String candidate) {
        votes.deleteCandidate(a.getId(), type, candidate);
        for (var m : members.findAllByAppointmentIdOrderByJoinedAtAsc(a.getId())) {
            if (m.getRole() != AppointmentMemberRole.HOST && !m.isRegardlessOfTimeAndPlace()
                    && !votes.existsByAppointmentIdAndUserId(a.getId(), m.getUser().getId())) participation.remove(m);
        }
    }
    private Appointment host(String id, String user) {
        Appointment a = appointments.findByIdForUpdate(id).orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
        rooms.requireMember(a.getRoomId(), user);
        if (!a.getHostId().equals(user)) throw new BusinessException(ErrorCode.APPOINTMENT_HOST_ONLY);
        return a;
    }
    private void coordinating(Appointment a, VoteType type) {
        if (a.getStatus() != AppointmentStatus.COORDINATING) throw new BusinessException(ErrorCode.NOT_COORDINATING);
        if (type == VoteType.TIME ? !a.getTemplate().coordinatesTime() || a.getConfirmedTime() != null
                : !a.getTemplate().coordinatesPlace() || a.getConfirmedPlace() != null) throw new BusinessException(ErrorCode.VOTE_NOT_ALLOWED);
    }
    private void editable(Appointment a, VoteType type) {
        coordinating(a, type);
        if (a.poll(type).closed()) throw new BusinessException(ErrorCode.POLL_CLOSED);
    }
}
