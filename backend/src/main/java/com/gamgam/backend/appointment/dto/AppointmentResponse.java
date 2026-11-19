package com.gamgam.backend.appointment.dto;

import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.PenaltyRule;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.appointment.vo.RewardRule;
import com.gamgam.backend.global.util.KstTimeConverter;

import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;

public record AppointmentResponse(
        String id,
        String roomId,
        String name,
        AppointmentTemplate template,
        List<TimeCandidateResponse> candidatesTime,
        OffsetDateTime confirmedTime,
        List<PlaceCandidateResponse> candidatesPlace,
        Place confirmedPlace,
        PenaltyRule penalty,
        RewardRule reward,
        LocationSharingPolicy locationSharing,
        AppointmentStatus status,
        String shareUrl,
        Instant createdAt,
        String hostId,
        String inviteCode,
        List<AppointmentMemberResponse> members,
        Map<String, List<String>> timeVotes,
        Map<String, List<String>> placeVotes
) {
    public record TimeCandidateResponse(String candidateId, OffsetDateTime time) {}
    public record PlaceCandidateResponse(String candidateId, Place place) {}

    public AppointmentResponse(String id, String name, AppointmentTemplate template,
                               List<TimeCandidateResponse> candidatesTime, OffsetDateTime confirmedTime,
                               List<PlaceCandidateResponse> candidatesPlace, Place confirmedPlace,
                               PenaltyRule penalty, RewardRule reward, LocationSharingPolicy locationSharing,
                               AppointmentStatus status, String shareUrl, Instant createdAt) {
        this(id, null, name, template, candidatesTime, confirmedTime, candidatesPlace, confirmedPlace,
                penalty, reward, locationSharing, status, shareUrl, createdAt,
                null, null, List.of(), Map.of(), Map.of());
    }

    public static AppointmentResponse of(Appointment appointment, String shareUrl) {
        return new AppointmentResponse(
                appointment.getId(),
                appointment.getRoomId(),
                appointment.getName(),
                appointment.getTemplate(),
                // 시간 필드(candidatesTime, confirmedTime)는 DB엔 UTC로 저장돼 있고, 이 응답 DTO로 변환되는 시점에 KST(+09:00)로 바뀐다.
                appointment.getCandidatesTime().stream().map(candidate -> new TimeCandidateResponse(
                        candidate.getCandidateId(), KstTimeConverter.toKst(candidate.getTime()))).toList(),
                KstTimeConverter.toKst(appointment.getConfirmedTime()),
                appointment.getCandidatesPlace().stream().map(candidate -> new PlaceCandidateResponse(
                        candidate.getCandidateId(), candidate.getPlace())).toList(),
                appointment.getConfirmedPlace(),
                appointment.getPenalty(),
                appointment.getReward(),
                appointment.getLocationSharing(),
                appointment.getStatus(),
                shareUrl,
                appointment.getCreatedAt(), appointment.getHostId(), appointment.getInviteCode(),
                List.of(), Map.of(), Map.of());
    }

    public static AppointmentResponse of(Appointment appointment, String shareUrl,
                                         List<AppointmentMemberResponse> members,
                                         Map<String, List<String>> timeVotes,
                                         Map<String, List<String>> placeVotes) {
        AppointmentResponse base = of(appointment, shareUrl);
        return new AppointmentResponse(base.id, base.roomId, base.name, base.template, base.candidatesTime,
                base.confirmedTime, base.candidatesPlace, base.confirmedPlace, base.penalty, base.reward,
                base.locationSharing, base.status, base.shareUrl, base.createdAt,
                base.hostId, base.inviteCode, members, timeVotes, placeVotes);
    }
}
