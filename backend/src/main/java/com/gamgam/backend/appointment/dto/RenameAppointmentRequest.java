package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RenameAppointmentRequest(@NotBlank @Size(max = 50) String name) {
    public RenameAppointmentRequest {
        if (name != null) name = name.strip();
    }
}
