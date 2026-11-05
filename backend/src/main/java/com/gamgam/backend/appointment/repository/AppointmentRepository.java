package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.Appointment;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

public interface AppointmentRepository extends JpaRepository<Appointment, String> {
    Optional<Appointment> findByInviteCode(String inviteCode);
    boolean existsByInviteCode(String inviteCode);
    List<Appointment> findByRoomIdOrderByCreatedAtDesc(String roomId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Appointment a where a.id = :id")
    Optional<Appointment> findByIdForUpdate(@Param("id") String id);

    @Query("""
            select a from Appointment a
            where exists (select m.id from RoomMember m where m.room.id = a.roomId and m.user.id = :userId)
            order by a.createdAt desc
            """)
    List<Appointment> findAllForUser(String userId);
}
