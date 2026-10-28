package com.gamgam.backend.appointment.dto;

import com.gamgam.backend.appointment.entity.AppointmentMember;
import com.gamgam.backend.appointment.vo.AppointmentMemberRole;
import java.time.Instant;

public record AppointmentMemberResponse(String userId, String name, AppointmentMemberRole role, Instant joinedAt) {
    public static AppointmentMemberResponse from(AppointmentMember member) {
        return new AppointmentMemberResponse(
                member.getUser().getId(), member.getUser().getName(), member.getRole(), member.getJoinedAt());
    }
}
