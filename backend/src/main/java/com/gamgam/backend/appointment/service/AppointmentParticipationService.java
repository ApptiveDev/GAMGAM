package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.entity.AppointmentMember;
import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentVoteRepository;
import com.gamgam.backend.appointment.vo.VoteType;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AppointmentParticipationService {
    private final AppointmentMemberRepository members;
    private final AppointmentVoteRepository votes;
    private final com.gamgam.backend.map.LiveLocationRepository locations;
    private final com.gamgam.backend.map.AttendanceRepository attendance;

    // 약속을 잠금 처리한 후, 호출한 쪽의 트랜잭션 내에서 호출.
    @Transactional(propagation = Propagation.MANDATORY)
    public void remove(AppointmentMember member) {
        String appointmentId = member.getAppointment().getId();
        String userId = member.getUser().getId();
        votes.deleteSelection(appointmentId, userId, VoteType.TIME);
        votes.deleteSelection(appointmentId, userId, VoteType.PLACE);
        locations.deleteByRoomIdAndUserId(appointmentId, userId);
        attendance.deleteByAppointmentIdAndUserId(appointmentId, userId);
        members.delete(member);
    }
}
