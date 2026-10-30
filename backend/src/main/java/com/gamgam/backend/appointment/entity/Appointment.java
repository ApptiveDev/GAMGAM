package com.gamgam.backend.appointment.entity;

import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.PenaltyRule;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.appointment.vo.RewardRule;
import jakarta.persistence.*;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.AccessLevel;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.jpa.domain.support.AuditingEntityListener;

@Entity
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
@EntityListeners(AuditingEntityListener.class)
@Table(name = "appointments")
public class Appointment {
    @Id @Column(length = 36)
    private String id;
    @Column(nullable = false, length = 50)
    private String name;
    @Column(name = "room_id", nullable = false, length = 64)
    private String roomId;
    @Column(name = "host_id", nullable = false, length = 36)
    private String hostId;
    @Column(name = "invite_code", nullable = false, unique = true, length = 12)
    private String inviteCode;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20)
    private AppointmentTemplate template;
    @ElementCollection
    @CollectionTable(name = "appointment_candidate_times", joinColumns = @JoinColumn(name = "appointment_id"))
    @OrderColumn(name = "candidate_order") @Column(name = "candidate_time", nullable = false)
    private List<OffsetDateTime> candidatesTime = new ArrayList<>();
    @Column(name = "confirmed_time")
    private OffsetDateTime confirmedTime;
    @ElementCollection
    @CollectionTable(name = "appointment_candidate_places", joinColumns = @JoinColumn(name = "appointment_id"))
    @OrderColumn(name = "candidate_order")
    private List<Place> candidatesPlace = new ArrayList<>();
    @Embedded private Place confirmedPlace;
    @Embedded private PenaltyRule penalty;
    @Embedded private RewardRule reward;
    @Embedded private LocationSharingPolicy locationSharing;
    @Enumerated(EnumType.STRING) @Column(nullable = false, length = 20)
    private AppointmentStatus status;
    @CreatedDate @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Builder
    public Appointment(String id, String name, String roomId, String hostId, String inviteCode,
                       AppointmentTemplate template, List<OffsetDateTime> candidatesTime,
                       OffsetDateTime confirmedTime, List<Place> candidatesPlace, Place confirmedPlace,
                       PenaltyRule penalty, RewardRule reward, LocationSharingPolicy locationSharing,
                       AppointmentStatus status) {
        if (roomId == null || roomId.isBlank()) throw new IllegalArgumentException("roomId is required");
        this.id = id;
        this.name = name;
        this.roomId = roomId;
        this.hostId = hostId;
        this.inviteCode = inviteCode;
        this.template = template;
        if (candidatesTime != null) this.candidatesTime.addAll(candidatesTime);
        this.confirmedTime = confirmedTime;
        if (candidatesPlace != null) this.candidatesPlace.addAll(candidatesPlace);
        this.confirmedPlace = confirmedPlace;
        this.penalty = penalty;
        this.reward = reward;
        this.locationSharing = locationSharing;
        this.status = status;
    }

    public void confirm(Integer timeOptionIndex, Integer placeOptionIndex) {
        if (template.coordinatesTime()) confirmedTime = candidatesTime.get(timeOptionIndex);
        if (template.coordinatesPlace()) confirmedPlace = candidatesPlace.get(placeOptionIndex);
        status = AppointmentStatus.CONFIRMED;
    }

    public void addCandidateTime(OffsetDateTime time) { candidatesTime.add(time); }
    public void addCandidatePlace(Place place) { candidatesPlace.add(place); }
    public void updatePenalty(PenaltyRule penalty) { this.penalty = penalty; }
    public void complete() { status = AppointmentStatus.COMPLETED; }
}
