package com.gamgam.backend.room;

import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomMemberRepository extends JpaRepository<RoomMember, String> {
    boolean existsByRoomIdAndUserId(String roomId, String userId);
    long countByRoomId(String roomId);
}
