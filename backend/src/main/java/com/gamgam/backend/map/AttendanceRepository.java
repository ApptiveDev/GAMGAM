package com.gamgam.backend.map;
import java.util.*;
import org.springframework.data.jpa.repository.JpaRepository;
public interface AttendanceRepository extends JpaRepository<Attendance,String> {
    Optional<Attendance> findByAppointmentIdAndUserId(String appointmentId,String userId);
    List<Attendance> findByAppointmentId(String appointmentId);
    void deleteByAppointmentIdAndUserId(String appointmentId,String userId);
}
