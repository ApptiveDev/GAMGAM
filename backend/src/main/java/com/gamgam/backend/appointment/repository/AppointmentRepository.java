package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.Appointment;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface AppointmentRepository extends JpaRepository<Appointment, String> {
    Optional<Appointment> findByInviteCode(String inviteCode);
    boolean existsByInviteCode(String inviteCode);
    List<Appointment> findByRoomIdOrderByCreatedAtDesc(String roomId);

    @Query("""
            select a from Appointment a
            where exists (select m.id from AppointmentMember m where m.appointment = a and m.user.id = :userId)
            order by a.createdAt desc
            """)
    List<Appointment> findAllForUser(String userId);

    @Query("""
            select a from Appointment a
            where a.roomId = :roomId
              and exists (select m.id from AppointmentMember m where m.appointment = a and m.user.id = :userId)
            order by a.createdAt desc
            """)
    List<Appointment> findAllForUserInRoom(String roomId, String userId);
}
