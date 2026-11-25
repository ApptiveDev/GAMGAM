package com.gamgam.backend.room;

import org.springframework.data.jpa.repository.JpaRepository;

public interface RoomMemberRepository extends JpaRepository<RoomMember, String> {
    boolean existsByRoomIdAndUserId(String roomId, String userId);
    java.util.List<RoomMember> findByRoomIdOrderByIdAsc(String roomId);
    long countByRoomId(String roomId);
}
