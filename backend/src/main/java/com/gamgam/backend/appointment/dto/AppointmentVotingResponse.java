package com.gamgam.backend.appointment.dto;

import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.Place;
import java.time.OffsetDateTime;
import java.util.List;

public record AppointmentVotingResponse(
        String appointmentId,
        String roomId,
        AppointmentStatus status,
        boolean participating,
        List<String> participantIds,
        boolean participatingRegardless,
        List<String> regardlessParticipantIds,
        List<TimeOption> timeOptions,
        List<PlaceOption> placeOptions) {

    public record TimeOption(int index, OffsetDateTime time, int voteCount,
                             List<String> voterIds, boolean votedByMe) {
    }

    public record PlaceOption(int index, Place place, int voteCount,
                              List<String> voterIds, boolean votedByMe) {
    }
}
