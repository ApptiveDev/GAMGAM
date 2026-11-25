package com.gamgam.backend.appointment.entity;

import jakarta.persistence.*;
import java.time.OffsetDateTime;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "appointment_candidate_times")
public class AppointmentTimeCandidate {
    @Id
    @Column(name = "candidate_id", length = 36)
    private String candidateId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "appointment_id", nullable = false)
    private Appointment appointment;

    @Column(name = "candidate_time", nullable = false)
    private OffsetDateTime time;

    public void change(OffsetDateTime value) { this.time = value; }

    public AppointmentTimeCandidate(Appointment appointment, OffsetDateTime time) {
        this.candidateId = UUID.randomUUID().toString();
        this.appointment = appointment;
        this.time = time;
    }
}
