package com.gamgam.backend.appointment.repository;

import com.gamgam.backend.appointment.entity.Appointment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;

import java.util.List;
import java.util.Optional;

public interface AppointmentRepository extends JpaRepository<Appointment, String> {
    List<Appointment> findByRoomIdOrderByCreatedAtDesc(String roomId);

    // 동시성 충돌 방지: 투표 교체와 후보 추가는 같은 약속 행을 잠가 순서대로 처리한다.
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select a from Appointment a where a.id = :id")
    Optional<Appointment> findByIdForUpdate(@Param("id") String id);
}
