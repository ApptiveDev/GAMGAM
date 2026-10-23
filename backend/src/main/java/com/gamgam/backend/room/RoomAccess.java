package com.gamgam.backend.room;

/** 방 담당자가 실제 방 존재 여부와 멤버십 조회로 구현할 연결 지점. */
public interface RoomAccess {
    void requireMember(String roomId, String userId);
}
