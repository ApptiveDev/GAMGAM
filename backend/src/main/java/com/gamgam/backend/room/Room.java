package com.gamgam.backend.room;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EntityListeners;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
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
@Table(name = "rooms")
public class Room {
    @Id
    @Column(length = 36)
    private String id;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(name = "owner_id", nullable = false, length = 36)
    private String ownerId;

    @CreatedDate
    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @Column(unique = true, length = 36)
    private String inviteCode;
    @Column(length = 2048)
    private String coverImageUrl;
    public void rename(String name) { this.name = name; }
    public void setCoverImageUrl(String value) { this.coverImageUrl = value; }
    public String ensureInviteCode() {
        if (inviteCode == null) inviteCode = java.util.UUID.randomUUID().toString();
        return inviteCode;
    }
    public void rotateInviteCode() { inviteCode = java.util.UUID.randomUUID().toString(); }

    public Room(String id, String name, String ownerId) {
        this.id = id;
        this.name = name;
        this.ownerId = ownerId;
    }
}
