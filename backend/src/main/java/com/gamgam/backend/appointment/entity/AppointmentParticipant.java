package com.gamgam.backend.appointment.entity;

import jakarta.persistence.*;
import java.time.Instant;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "appointment_participants", uniqueConstraints = @UniqueConstraint(
        columnNames = {"appointment_id", "user_id"}))
// 약속 참여자 (투표 시 참여자로)
public class AppointmentParticipant {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "appointment_id", nullable = false)
    private Appointment appointment;

    @Column(name = "user_id", nullable = false, length = 36)
    private String userId;

    // 참여자로 등록된 시각
    @Column(nullable = false, updatable = false)
    private Instant joinedAt;

    // '시간·장소 상관없이 참여' 선택 여부
    @Column(nullable = false)
    private boolean regardlessOfTimeAndPlace;

    public AppointmentParticipant(Appointment appointment, String userId) {
        this.appointment = appointment;
        this.userId = userId;
        this.joinedAt = Instant.now();
    }

    public void setRegardlessOfTimeAndPlace(boolean selected) {
        this.regardlessOfTimeAndPlace = selected;
    }
}
