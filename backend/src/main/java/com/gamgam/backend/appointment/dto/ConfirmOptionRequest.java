package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

public record ConfirmOptionRequest(@NotNull @PositiveOrZero Integer optionIndex) {}
