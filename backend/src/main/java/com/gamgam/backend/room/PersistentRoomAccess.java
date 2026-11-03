package com.gamgam.backend.room;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;

@Component
@Profile("!local")
@RequiredArgsConstructor
public class PersistentRoomAccess implements RoomAccess {
    private final RoomRepository rooms;
    private final RoomMemberRepository members;

    @Override
    public void requireMember(String roomId, String userId) {
        if (!rooms.existsById(roomId)) throw new BusinessException(ErrorCode.ROOM_NOT_FOUND);
        if (!members.existsByRoomIdAndUserId(roomId, userId)) {
            throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
        }
    }
}
