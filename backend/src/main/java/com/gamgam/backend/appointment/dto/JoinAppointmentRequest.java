package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record JoinAppointmentRequest(@NotBlank @Size(max = 12) String inviteCode) {
}
