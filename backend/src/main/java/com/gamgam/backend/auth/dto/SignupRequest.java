package com.gamgam.backend.auth.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record SignupRequest(
        @NotBlank(message = "Email is required.")
        @Email(message = "Email format is invalid.")
        @Size(max = 255, message = "Email must be at most 255 characters.")
        String email,

        @NotBlank(message = "Password is required.")
        @Size(min = 8, max = 64, message = "Password must be between 8 and 64 characters.")
        String password,

        @NotBlank(message = "Name is required.")
        @Size(min = 2, max = 30, message = "Name must be between 2 and 30 characters.")
        String name
) {
}
