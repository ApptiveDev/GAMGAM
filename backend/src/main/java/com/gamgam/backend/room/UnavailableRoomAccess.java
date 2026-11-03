package com.gamgam.backend.room;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;

/** Legacy fallback retained for compatibility; no longer registered as a Spring bean. */
public class UnavailableRoomAccess implements RoomAccess {
    @Override
    public void requireMember(String roomId, String userId) {
        throw new BusinessException(ErrorCode.ROOM_INTEGRATION_UNAVAILABLE);
    }
}
