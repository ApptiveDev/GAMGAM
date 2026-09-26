package com.gamgam.backend.appointment.entity;

import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.PenaltyRule;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.appointment.vo.RewardRule;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)
@Table(name = "appointments")
public class Appointment {

    @Id
    @Column(length = 36)
    private String id;

    @Column(nullable = false, length = 50)
    private String name;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AppointmentTemplate template; // 약속 조율 템플릿(시간만 조율, 장소만 조율 등)

    @ElementCollection
    @CollectionTable(name = "appointment_candidate_times", joinColumns = @JoinColumn(name = "appointment_id"))
    @OrderColumn(name = "candidate_order")
    @Column(name = "candidate_time", nullable = false)
    private List<OffsetDateTime> candidatesTime = new ArrayList<>(); // 약속 시간 후보 리스트

    @Column(name = "confirmed_time")
    private OffsetDateTime confirmedTime; // 확정된 약속 시간

    @ElementCollection
    @CollectionTable(name = "appointment_candidate_places", joinColumns = @JoinColumn(name = "appointment_id"))
    @OrderColumn(name = "candidate_order")
    private List<Place> candidatesPlace = new ArrayList<>(); // 약속 장소 후보 리스트

    @Embedded
    private Place confirmedPlace; // 확정된 약속 장소

    @Embedded
    private PenaltyRule penalty; // 벌칙 규칙(벌칙 기준, 종류 등)

    @Embedded
    private RewardRule reward; // 보상 규칙

    @Embedded
    private LocationSharingPolicy locationSharing; // 위치 공유 규칙(위치 공유 시간)

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private AppointmentStatus status; // 약속 상태(조율 중, 확정, 종료)

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private OffsetDateTime createdAt;

    @Builder
    public Appointment(String id, String name, AppointmentTemplate template,
                       List<OffsetDateTime> candidatesTime, OffsetDateTime confirmedTime,
                       List<Place> candidatesPlace, Place confirmedPlace,
                       PenaltyRule penalty, RewardRule reward,
                       LocationSharingPolicy locationSharing,
                       AppointmentStatus status, OffsetDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.template = template;
        this.candidatesTime = candidatesTime != null ? candidatesTime : new ArrayList<>();
        this.confirmedTime = confirmedTime;
        this.candidatesPlace = candidatesPlace != null ? candidatesPlace : new ArrayList<>();
        this.confirmedPlace = confirmedPlace;
        this.penalty = penalty;
        this.reward = reward;
        this.locationSharing = locationSharing;
        this.status = status;
    }
}
