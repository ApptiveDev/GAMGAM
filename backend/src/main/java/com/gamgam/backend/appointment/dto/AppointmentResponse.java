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

public record AppointmentResponse(
        String id,
        String name,
        AppointmentTemplate template,
        List<OffsetDateTime> candidatesTime,
        OffsetDateTime confirmedTime,
        List<Place> candidatesPlace,
        Place confirmedPlace,
        PenaltyRule penalty,
        RewardRule reward,
        LocationSharingPolicy locationSharing,
        AppointmentStatus status,
        String shareUrl,
        Instant createdAt
) {
    public static AppointmentResponse of(Appointment appointment, String shareUrl) {
        return new AppointmentResponse(
                appointment.getId(),
                appointment.getName(),
                appointment.getTemplate(),
                // 시간 필드(candidatesTime, confirmedTime)는 DB엔 UTC로 저장돼 있고, 이 응답 DTO로 변환되는 시점에 KST(+09:00)로 바뀐다.
                KstTimeConverter.toKst(appointment.getCandidatesTime()),
                KstTimeConverter.toKst(appointment.getConfirmedTime()),
                appointment.getCandidatesPlace(),
                appointment.getConfirmedPlace(),
                appointment.getPenalty(),
                appointment.getReward(),
                appointment.getLocationSharing(),
                appointment.getStatus(),
                shareUrl,
                appointment.getCreatedAt());
    }
}
