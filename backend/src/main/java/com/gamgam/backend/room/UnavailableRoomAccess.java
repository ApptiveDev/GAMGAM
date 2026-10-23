package com.gamgam.backend.room;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/** 운영 연결 전에는 가짜 멤버십을 허용하지 않는다. 실제 RoomAccess 구현으로 교체한다. */
@Component
@Profile("!local")
public class UnavailableRoomAccess implements RoomAccess {
    @Override
    public void requireMember(String roomId, String userId) {
        throw new BusinessException(ErrorCode.ROOM_INTEGRATION_UNAVAILABLE);
    }
}
