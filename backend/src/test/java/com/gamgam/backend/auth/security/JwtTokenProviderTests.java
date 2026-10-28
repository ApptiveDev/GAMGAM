package com.gamgam.backend.auth.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.user.entity.User;
import org.junit.jupiter.api.Test;

class JwtTokenProviderTests {
    private final JwtTokenProvider provider = new JwtTokenProvider(
            new JwtProperties("test-jwt-secret-that-is-longer-than-thirty-two-bytes", 3600));

    @Test
    void createdTokenResolvesAuthenticatedUser() {
        User user = User.builder().id("user-1").email("user@example.com").name("User").passwordHash("hash").build();
        String token = provider.create(user).value();
        assertThat(provider.verifyAndGetUserId(token)).isEqualTo("user-1");
    }

    @Test
    void tamperedTokenIsRejected() {
        User user = User.builder().id("user-1").email("user@example.com").name("User").passwordHash("hash").build();
        String token = provider.create(user).value();
        String tampered = token.substring(0, token.length() - 1) + (token.endsWith("A") ? "B" : "A");
        assertThatThrownBy(() -> provider.verifyAndGetUserId(tampered))
                .isInstanceOfSatisfying(BusinessException.class,
                        error -> assertThat(error.errorCode()).isEqualTo(ErrorCode.INVALID_TOKEN));
    }
}
