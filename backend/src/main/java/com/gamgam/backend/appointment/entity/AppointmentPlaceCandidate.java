package com.gamgam.backend.appointment.entity;

import com.gamgam.backend.appointment.vo.Place;
import jakarta.persistence.*;
import java.util.UUID;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "appointment_candidate_places")
public class AppointmentPlaceCandidate {
    @Id
    @Column(name = "candidate_id", length = 36)
    private String candidateId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "appointment_id", nullable = false)
    private Appointment appointment;

    @Embedded
    private Place place;

    public AppointmentPlaceCandidate(Appointment appointment, Place place) {
        this.candidateId = UUID.randomUUID().toString();
        this.appointment = appointment;
        this.place = place;
    }
}
