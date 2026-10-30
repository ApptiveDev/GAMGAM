package com.gamgam.backend.appointment.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "appointment_place_votes",
        uniqueConstraints = @UniqueConstraint(columnNames = {"appointment_id", "user_id"}))
public class AppointmentPlaceVote {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    @Column(name = "appointment_id", nullable = false, length = 36)
    private String appointmentId;
    @Column(name = "user_id", nullable = false, length = 36)
    private String userId;
    @Column(name = "option_index", nullable = false)
    private int optionIndex;

    public AppointmentPlaceVote(String appointmentId, String userId, int optionIndex) {
        this.appointmentId = appointmentId;
        this.userId = userId;
        this.optionIndex = optionIndex;
    }
}
