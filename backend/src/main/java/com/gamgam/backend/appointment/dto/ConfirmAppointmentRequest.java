package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.PositiveOrZero;

public record ConfirmAppointmentRequest(
        @PositiveOrZero Integer timeOptionIndex,
        @PositiveOrZero Integer placeOptionIndex
) {
}
