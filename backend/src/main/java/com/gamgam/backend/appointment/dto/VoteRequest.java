package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.Set;

public record VoteRequest(@NotNull Set<@NotNull @Min(0) Integer> optionIndexes) {
}
