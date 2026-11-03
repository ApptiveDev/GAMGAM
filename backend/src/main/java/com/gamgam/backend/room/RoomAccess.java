package com.gamgam.backend.room;

/** Checks whether a user belongs to a room. */
public interface RoomAccess {
    void requireMember(String roomId, String userId);
}
