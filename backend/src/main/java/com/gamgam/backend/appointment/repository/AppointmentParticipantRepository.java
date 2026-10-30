package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.AppointmentParticipant;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppointmentParticipantRepository extends JpaRepository<AppointmentParticipant, Long> {
    Optional<AppointmentParticipant> findByAppointmentIdAndUserId(String appointmentId, String userId);
    List<AppointmentParticipant> findByAppointmentIdOrderByJoinedAtAscIdAsc(String appointmentId);
    void deleteAllByAppointmentIdAndUserId(String appointmentId, String userId);
}
