package com.gamgam.backend.room;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.user.repository.UserRepository;
import java.util.List;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class RoomService {
    private final RoomRepository rooms;
    private final RoomMemberRepository members;
    private final UserRepository users;
    private final RoomAccess access;

    @Transactional
    public RoomResponse create(String userId, CreateRoomRequest request) {
        User owner = users.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        Room room = rooms.save(new Room(UUID.randomUUID().toString(), request.name().trim(), userId));
        members.save(new RoomMember(UUID.randomUUID().toString(), room, owner));
        return RoomResponse.from(room, 1);
    }

    public List<RoomResponse> list(String userId) {
        return rooms.findAllForUser(userId).stream().map(this::toResponse).toList();
    }

    public RoomResponse get(String userId, String roomId) {
        access.requireMember(roomId, userId);
        return toResponse(rooms.findById(roomId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROOM_NOT_FOUND)));
    }

    private RoomResponse toResponse(Room room) {
        return RoomResponse.from(room, members.countByRoomId(room.getId()));
    }
}
