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
        columnNames = {"appointment_id", "user_id", "vote_type", "option_index"}))
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

    @Column(name = "option_index", nullable = false)
    private int optionIndex;

    public AppointmentVote(Appointment appointment, String userId, VoteType type, int optionIndex) {
        this.appointment = appointment;
        this.userId = userId;
        this.type = type;
        this.optionIndex = optionIndex;
    }
}
