package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.AppointmentPlaceVote;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppointmentPlaceVoteRepository extends JpaRepository<AppointmentPlaceVote, Long> {
    Optional<AppointmentPlaceVote> findByAppointmentIdAndUserId(String appointmentId, String userId);
    List<AppointmentPlaceVote> findAllByAppointmentId(String appointmentId);
    void deleteAllByAppointmentIdAndUserId(String appointmentId, String userId);
}
