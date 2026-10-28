package com.gamgam.backend.appointment.entity;

import com.gamgam.backend.appointment.vo.AppointmentMemberRole;
import com.gamgam.backend.user.entity.User;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)
@Table(name = "appointment_members",
        uniqueConstraints = @UniqueConstraint(columnNames = {"appointment_id", "user_id"}))
public class AppointmentMember {

    @Id
    @Column(length = 36)
    private String id;

    @ManyToOne(optional = false)
    @JoinColumn(name = "appointment_id", nullable = false)
    private Appointment appointment;

    @ManyToOne(optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    private AppointmentMemberRole role;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private Instant joinedAt;

    public AppointmentMember(String id, Appointment appointment, User user, AppointmentMemberRole role) {
        this.id = id;
        this.appointment = appointment;
        this.user = user;
        this.role = role;
    }
}
