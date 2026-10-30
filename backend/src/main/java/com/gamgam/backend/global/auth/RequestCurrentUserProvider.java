package com.gamgam.backend.global.auth;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.core.env.Environment;
import org.springframework.core.env.Profiles;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class RequestCurrentUserProvider implements CurrentUserProvider {
    private final HttpServletRequest request;
    private final Environment environment;

    @Override
    public String userId() {
        String id = request.getUserPrincipal() == null ? null : request.getUserPrincipal().getName();
        // 로컬 수동 테스트 전용. 운영에서는 클라이언트 헤더를 신뢰하지 않는다.
        if (id == null && environment.acceptsProfiles(Profiles.of("local"))) {
            id = request.getHeader("X-User-Id");
            if (id == null) id = "u-yeeun";
        }
        if (id == null || id.isBlank()) throw new BusinessException(ErrorCode.UNAUTHENTICATED);
        if (id.length() > 36) throw new BusinessException(ErrorCode.BAD_REQUEST);
        return id;
    }
}
