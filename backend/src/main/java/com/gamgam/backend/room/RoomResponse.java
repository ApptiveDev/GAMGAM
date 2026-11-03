package com.gamgam.backend.room;

import java.time.Instant;

public record RoomResponse(String id, String name, String ownerId, long memberCount, Instant createdAt) {
    public static RoomResponse from(Room room, long memberCount) {
        return new RoomResponse(room.getId(), room.getName(), room.getOwnerId(), memberCount, room.getCreatedAt());
    }
}
