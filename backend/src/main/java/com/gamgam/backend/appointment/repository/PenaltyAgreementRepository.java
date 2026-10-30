package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.PenaltyAgreement;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PenaltyAgreementRepository extends JpaRepository<PenaltyAgreement, Long> {
    Optional<PenaltyAgreement> findByAppointmentIdAndUserId(String appointmentId, String userId);
    List<PenaltyAgreement> findAllByAppointmentId(String appointmentId);
    void deleteAllByAppointmentIdAndUserId(String appointmentId, String userId);
}
