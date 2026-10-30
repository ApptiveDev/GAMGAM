package com.gamgam.backend.appointment.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "appointment_participants", uniqueConstraints = @UniqueConstraint(
        columnNames = {"appointment_id", "user_id"}))
public class AppointmentParticipant {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "appointment_id", nullable = false)
    private Appointment appointment;

    @Column(name = "user_id", nullable = false, length = 36)
    private String userId;

    @Column(nullable = false, updatable = false)
    private Instant joinedAt;

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
