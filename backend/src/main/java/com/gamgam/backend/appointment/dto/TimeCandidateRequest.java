package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotNull;
import java.time.OffsetDateTime;

public record TimeCandidateRequest(@NotNull @Future OffsetDateTime time) {
}
