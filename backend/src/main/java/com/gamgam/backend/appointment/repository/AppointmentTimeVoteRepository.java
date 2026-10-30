package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.AppointmentTimeVote;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppointmentTimeVoteRepository extends JpaRepository<AppointmentTimeVote, Long> {
    Optional<AppointmentTimeVote> findByAppointmentIdAndUserIdAndOptionIndex(String appointmentId, String userId, int optionIndex);
    List<AppointmentTimeVote> findAllByAppointmentId(String appointmentId);
    List<AppointmentTimeVote> findAllByAppointmentIdAndUserId(String appointmentId, String userId);
    boolean existsByAppointmentIdAndUserId(String appointmentId, String userId);
    void deleteAllByAppointmentIdAndUserId(String appointmentId, String userId);
}
