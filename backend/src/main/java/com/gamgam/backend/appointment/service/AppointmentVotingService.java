package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.entity.AppointmentParticipant;
import com.gamgam.backend.appointment.repository.AppointmentParticipantRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.entity.AppointmentVote;
import com.gamgam.backend.appointment.repository.AppointmentVoteRepository;
import com.gamgam.backend.appointment.vo.VoteType;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.global.util.KstTimeConverter;
import com.gamgam.backend.room.RoomAccess;
import java.util.List;
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
        return response(load(id, userId), userId);
    }

    private Appointment load(String id, String userId) {
        Appointment appointment = appointments.findById(id)
                .orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
        rooms.requireMember(appointment.getRoomId(), userId);
        return appointment;
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
