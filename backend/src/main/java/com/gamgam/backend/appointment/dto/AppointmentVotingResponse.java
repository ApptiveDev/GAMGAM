package com.gamgam.backend.appointment.dto;

import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.Place;
import java.time.OffsetDateTime;
import java.util.List;

public record AppointmentVotingResponse(
        String appointmentId,
        String roomId,
        AppointmentStatus status,
        // 요청한 사용자가 이 약속의 참여자인지
        boolean participating,
        List<String> participantIds,
        // ‘시간·장소 상관없이 참여’를 선택했는지
        boolean participatingRegardless,
        // ‘시간·장소 상관없이 참여’ 선택을 한 참여자들의 ID
        List<String> regardlessParticipantIds,
        // 시간 후보별 투표 현황
        List<TimeOption> timeOptions,
        // 장소 후보별 투표 현황
        List<PlaceOption> placeOptions,
        PollResponse timePoll, PollResponse placePoll) {
    public record PollResponse(boolean multipleSelection, boolean anonymous, boolean allowAddingOptions,
            String state, java.time.Instant startedAt, java.time.Instant endsAt,
            String giftDescription, com.gamgam.backend.appointment.vo.PollSettings.GiftMethod giftMethod,
            Integer winnerCount, List<String> winnerIds) {
        public static PollResponse from(com.gamgam.backend.appointment.vo.PollSettings p, boolean confirmed, boolean empty) {
            return new PollResponse(p.isMultipleSelection(), p.isAnonymous(), p.isAllowAddingOptions(),
                    confirmed ? "CONFIRMED" : p.closed() ? "CLOSED" : empty ? "EMPTY" : "OPEN",
                    p.getStartedAt(), p.getEndsAt(), p.getGiftDescription(), p.getGiftMethod(), p.getWinnerCount(),
                    p.getWinnerIds() == null || p.getWinnerIds().isEmpty() ? List.of() : List.of(p.getWinnerIds().split(",")));
        }
    }
    public record TimeOption(String candidateId, OffsetDateTime time, int voteCount,
                             List<String> voterIds, boolean votedByMe) {}
    public record PlaceOption(String candidateId, Place place, int voteCount,
                              List<String> voterIds, boolean votedByMe) {}
}
