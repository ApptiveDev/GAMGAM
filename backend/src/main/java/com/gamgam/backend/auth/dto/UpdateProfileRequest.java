package com.gamgam.backend.auth.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateProfileRequest(
        @NotBlank(message = "Name is required.")
        @Size(min = 2, max = 30, message = "Name must be between 2 and 30 characters.")
        String name
) {
}
