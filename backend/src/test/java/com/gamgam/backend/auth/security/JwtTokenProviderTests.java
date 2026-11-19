package com.gamgam.backend.auth.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.user.entity.User;
import java.util.Base64;
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
        int signatureStart = token.lastIndexOf('.') + 1;
        byte[] signature = Base64.getUrlDecoder().decode(token.substring(signatureStart));
        // 마지막 인코딩 문자의 미사용 비트가 아닌 실제 서명 비트를 변경한다.
        signature[0] ^= 1;
        String tampered = token.substring(0, signatureStart)
                + Base64.getUrlEncoder().withoutPadding().encodeToString(signature);
        assertThatThrownBy(() -> provider.verifyAndGetUserId(tampered))
                .isInstanceOfSatisfying(BusinessException.class,
                        error -> assertThat(error.errorCode()).isEqualTo(ErrorCode.INVALID_TOKEN));
    }
}
