package com.gamgam.backend.auth.dto;

import com.gamgam.backend.user.entity.User;
import java.time.Instant;

public record UserResponse(
        String id,
        String email,
        String name,
        Instant createdAt,
        String avatarUrl
) {
    public UserResponse(String id,String email,String name,Instant createdAt) { this(id,email,name,createdAt,null); }
    public static UserResponse from(User user) {
        return new UserResponse(user.getId(), user.getEmail(), user.getName(), user.getCreatedAt(), user.getAvatarUrl());
    }
}
