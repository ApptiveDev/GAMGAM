package com.gamgam.backend.room;

import java.time.Instant;

public record RoomResponse(String id, String name, String ownerId, long memberCount, Instant createdAt, String coverImageUrl) {
    public RoomResponse(String id,String name,String ownerId,long count,Instant createdAt) {this(id,name,ownerId,count,createdAt,null); }
    public static RoomResponse from(Room room, long memberCount) {
        return new RoomResponse(room.getId(), room.getName(), room.getOwnerId(), memberCount, room.getCreatedAt(),room.getCoverImageUrl());
    }
}
