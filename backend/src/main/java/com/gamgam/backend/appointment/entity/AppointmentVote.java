package com.gamgam.backend.appointment.entity;

import com.gamgam.backend.appointment.vo.VoteType;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@Table(name = "appointment_votes", uniqueConstraints = @UniqueConstraint(
        columnNames = {"appointment_id", "user_id", "vote_type", "candidate_id"}))
public class AppointmentVote {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "appointment_id", nullable = false)
    private Appointment appointment;

    @Column(name = "user_id", nullable = false, length = 36)
    private String userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "vote_type", nullable = false, length = 10)
    private VoteType type;

    @Column(name = "candidate_id", nullable = false, length = 36)
    private String candidateId;

    public AppointmentVote(Appointment appointment, String userId, VoteType type, String candidateId) {
        this.appointment = appointment;
        this.userId = userId;
        this.type = type;
        this.candidateId = candidateId;
    }
}
