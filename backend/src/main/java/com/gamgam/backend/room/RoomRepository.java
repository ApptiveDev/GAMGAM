package com.gamgam.backend.room;

import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface RoomRepository extends JpaRepository<Room, String> {
    @Query("""
            select r from Room r
            where exists (select m.id from RoomMember m where m.room = r and m.user.id = :userId)
            order by r.createdAt desc
            """)
    List<Room> findAllForUser(@Param("userId") String userId);
}
