package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.PositiveOrZero;

public record ConfirmOptionRequest(@PositiveOrZero Integer optionIndex) {}
