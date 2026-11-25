package com.gamgam.backend.map;

import jakarta.persistence.*;
import java.time.Instant;
import lombok.*;
@Entity @Getter @NoArgsConstructor(access=AccessLevel.PROTECTED)
@Table(name="poke_notifications", indexes={@Index(columnList="recipientId,createdAt"),@Index(columnList="appointmentId,senderId,recipientId,createdAt")})
public class PokeNotification {
    @Id private String id;
    @Column(nullable=false) private String appointmentId;
    @Column(nullable=false) private String senderId;
    @Column(nullable=false) private String recipientId;
    @Column(nullable=false) private Instant createdAt;
    private Instant readAt;
    public PokeNotification(String appointmentId,String senderId,String recipientId) {
        this.id=java.util.UUID.randomUUID().toString(); this.appointmentId=appointmentId; this.senderId=senderId;
        this.recipientId=recipientId; this.createdAt=Instant.now();
    }
    public void markRead() { if(readAt==null) readAt=Instant.now(); }
}
