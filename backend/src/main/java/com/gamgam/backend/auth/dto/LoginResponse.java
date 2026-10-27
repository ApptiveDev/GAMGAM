package com.gamgam.backend.auth.dto;

public record LoginResponse(
        String tokenType,
        String accessToken,
        long expiresIn,
        UserResponse user
) {
    public static LoginResponse bearer(String token, long expiresIn, UserResponse user) {
        return new LoginResponse("Bearer", token, expiresIn, user);
    }
}
