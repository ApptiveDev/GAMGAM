package com.gamgam.backend.global.auth;

import static org.assertj.core.api.Assertions.*;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.room.UnavailableRoomAccess;
import org.junit.jupiter.api.Test;
import org.springframework.mock.env.MockEnvironment;
import org.springframework.mock.web.MockHttpServletRequest;

class RequestCurrentUserProviderTests {
    @Test
    void 로컬에서만_테스트_헤더와_기본_사용자를_허용한다() {
        var request = new MockHttpServletRequest();
        var environment = new MockEnvironment();
        environment.setActiveProfiles("local");
        var users = new RequestCurrentUserProvider(request, environment);
        assertThat(users.userId()).isEqualTo("u-yeeun");
        request.addHeader("X-User-Id", "u-doyun");
        assertThat(users.userId()).isEqualTo("u-doyun");
    }

    @Test
    void 운영에서는_사용자_헤더를_인증으로_사용하지_않는다() {
        var request = new MockHttpServletRequest();
        request.addHeader("X-User-Id", "u-yeeun");
        var environment = new MockEnvironment();
        environment.setActiveProfiles("prod");
        var users = new RequestCurrentUserProvider(request, environment);
        assertThatThrownBy(users::userId).isInstanceOfSatisfying(BusinessException.class,
                ex -> assertThat(ex.errorCode()).isEqualTo(ErrorCode.UNAUTHENTICATED));
        request.setUserPrincipal(() -> "authenticated-user");
        assertThat(users.userId()).isEqualTo("authenticated-user");
    }

    @Test
    void 운영_방_연결이_없으면_가짜_멤버십을_허용하지_않는다() {
        assertThatThrownBy(() -> new UnavailableRoomAccess().requireMember("demo-room", "u-yeeun"))
                .isInstanceOfSatisfying(BusinessException.class,
                        ex -> assertThat(ex.errorCode()).isEqualTo(ErrorCode.ROOM_INTEGRATION_UNAVAILABLE));
    }
}
