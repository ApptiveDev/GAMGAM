package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.AppointmentPlaceVote;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppointmentPlaceVoteRepository extends JpaRepository<AppointmentPlaceVote, Long> {
    List<AppointmentPlaceVote> findAllByAppointmentId(String appointmentId);
    List<AppointmentPlaceVote> findAllByAppointmentIdAndUserId(String appointmentId, String userId);
    boolean existsByAppointmentIdAndUserId(String appointmentId, String userId);
    void deleteAllByAppointmentIdAndUserId(String appointmentId, String userId);
}
