package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.Appointment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface AppointmentRepository extends JpaRepository<Appointment, String> {
    List<Appointment> findAllByOrderByCreatedAtDesc();
    Optional<Appointment> findByInviteCode(String inviteCode);
    boolean existsByInviteCode(String inviteCode);

    @org.springframework.data.jpa.repository.Query("""
            select a from Appointment a
            where exists (select m.id from AppointmentMember m where m.appointment = a and m.user.id = :userId)
            order by a.createdAt desc
            """)
    List<Appointment> findAllForUser(String userId);
}
