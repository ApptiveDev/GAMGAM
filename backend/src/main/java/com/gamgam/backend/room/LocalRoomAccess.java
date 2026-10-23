package com.gamgam.backend.room;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import java.util.Set;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

/** 방 생성/초대 기능이 연결되기 전, 로컬 데모 방 하나만 제공한다. */
@Component
@Profile("local")
public class LocalRoomAccess implements RoomAccess {
    private static final Set<String> MEMBERS = Set.of("u-yeeun", "u-doyun", "u-seoa", "u-minjun", "u-harin");

    @Override
    public void requireMember(String roomId, String userId) {
        if (!"demo-room".equals(roomId)) {
            throw new BusinessException(ErrorCode.ROOM_NOT_FOUND);
        }
        if (!MEMBERS.contains(userId)) {
            throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
        }
    }
}
