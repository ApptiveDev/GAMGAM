package com.gamgam.backend.appointment.dto;

import com.gamgam.backend.appointment.vo.PollSettings.GiftMethod;
import jakarta.validation.constraints.*;
import java.util.Set;

public record PollSettingsRequest(
        @NotNull Boolean multipleSelection, @NotNull Boolean anonymous,
        @NotNull Boolean allowAddingOptions, @NotNull Integer durationMinutes,
        @Size(max = 100) String giftDescription, GiftMethod giftMethod,
        @Min(1) @Max(100) Integer winnerCount) {
    @AssertTrue(message = "durationMinutes must be 30, 60, 240, 480, 1440, 4320, 10080 or 20160")
    public boolean isDurationValid() { return durationMinutes != null && Set.of(30,60,240,480,1440,4320,10080,20160).contains(durationMinutes); }
    @AssertTrue(message = "giftDescription, giftMethod and winnerCount must be supplied together")
    public boolean isGiftValid() {
        return giftDescription == null && giftMethod == null && winnerCount == null
                || giftDescription != null && !giftDescription.isBlank() && giftMethod != null && winnerCount != null;
    }
}
