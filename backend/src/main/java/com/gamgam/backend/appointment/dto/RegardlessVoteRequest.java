package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.NotNull;

public record RegardlessVoteRequest(@NotNull Boolean selected) {
}
