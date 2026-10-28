package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.AppointmentMember;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AppointmentMemberRepository extends JpaRepository<AppointmentMember, String> {
    boolean existsByAppointmentIdAndUserId(String appointmentId, String userId);
    Optional<AppointmentMember> findByAppointmentIdAndUserId(String appointmentId, String userId);
    List<AppointmentMember> findAllByAppointmentIdOrderByJoinedAtAsc(String appointmentId);
}
