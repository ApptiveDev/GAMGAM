package com.gamgam.backend.appointment.dto;

import com.gamgam.backend.appointment.entity.AppointmentMember;
import com.gamgam.backend.appointment.vo.AppointmentMemberRole;
import java.time.Instant;

public record AppointmentMemberResponse(String userId, String name, AppointmentMemberRole role, Instant joinedAt, String avatarUrl) {
    public AppointmentMemberResponse(String id,String name,AppointmentMemberRole role,Instant joinedAt) { this(id,name,role,joinedAt,null); }
    public static AppointmentMemberResponse from(AppointmentMember member) {
        return new AppointmentMemberResponse(
                member.getUser().getId(), member.getUser().getName(), member.getRole(), member.getJoinedAt(),member.getUser().getAvatarUrl());
    }
}
