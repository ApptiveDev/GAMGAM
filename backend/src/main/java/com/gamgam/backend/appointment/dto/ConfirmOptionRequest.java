package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.NotBlank;

public record ConfirmOptionRequest(@NotBlank String candidateId) {}
