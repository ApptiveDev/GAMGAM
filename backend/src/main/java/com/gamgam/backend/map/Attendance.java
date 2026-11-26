package com.gamgam.backend.map;

import jakarta.persistence.*;
import java.time.Instant;
import lombok.*;

@Entity @Getter @NoArgsConstructor(access=AccessLevel.PROTECTED)
@Table(name="appointment_attendance", uniqueConstraints=@UniqueConstraint(columnNames={"appointment_id","user_id"}))
public class Attendance {
    @Id private String id;
    @Column(name="appointment_id", nullable=false) private String appointmentId;
    @Column(name="user_id", nullable=false) private String userId;
    @Enumerated(EnumType.STRING) private State state = State.NOT_DEPARTED;
    @Enumerated(EnumType.STRING) private Transport transport;
    private Integer etaMinutes;
    @Column(length=200) private String statusMessage;
    private Instant arrivedAt;
    private Instant updatedAt;
    public enum State { NOT_DEPARTED, EN_ROUTE, ARRIVED }
    public enum Transport { WALK, BICYCLE, CAR, TRANSIT, OTHER }
    public Attendance(String appointmentId, String userId) {
        this.id=java.util.UUID.randomUUID().toString(); this.appointmentId=appointmentId; this.userId=userId;
    }
    public void update(AttendanceService.StatusRequest r) {
        state=r.state(); transport=r.transport(); etaMinutes=r.etaMinutes(); statusMessage=r.statusMessage();
        if (state == State.ARRIVED && arrivedAt == null) arrivedAt=Instant.now();
        if (state != State.ARRIVED) arrivedAt=null;
        updatedAt=Instant.now();
    }
}
