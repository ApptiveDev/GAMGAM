package com.gamgam.backend.appointment.repository;

import java.util.List;

import com.gamgam.backend.appointment.entity.AppointmentVote;
import com.gamgam.backend.appointment.vo.VoteType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface AppointmentVoteRepository extends JpaRepository<AppointmentVote, Long> {
    List<AppointmentVote> findByAppointmentIdOrderByIdAsc(String appointmentId);

    boolean existsByAppointmentIdAndUserId(String appointmentId, String userId);

    @Modifying(flushAutomatically = true)
    @Query("delete from AppointmentVote v where v.appointment.id = :id and v.userId = :userId and v.type = :type")
    void deleteSelection(@Param("id") String appointmentId, @Param("userId") String userId,
                         @Param("type") VoteType type);
}
