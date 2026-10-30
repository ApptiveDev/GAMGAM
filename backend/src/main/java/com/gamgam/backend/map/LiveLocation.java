package com.gamgam.backend.map;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import jakarta.persistence.UniqueConstraint;
import java.time.Instant;

@Entity
@Table(name = "live_locations", uniqueConstraints = @UniqueConstraint(columnNames = {"room_id", "user_id"}))
public class LiveLocation {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY) private Long id;
    @Column(name = "room_id", nullable = false) private String roomId;
    @Column(name = "user_id", nullable = false) private String userId;
    @Column(nullable = false) private String userName;
    @Column(nullable = false) private double latitude;
    @Column(nullable = false) private double longitude;
    @Column(nullable = false) private boolean sharingEnabled;
    @Column(nullable = false, length = 10) private String shareLevel = "BASIC";
    private Double speedKmh;
    @Column(length = 10) private String transport;
    @Column(nullable = false) private Instant updatedAt;

    protected LiveLocation() {}
    LiveLocation(String roomId, String userId, String userName, double latitude, double longitude, boolean sharingEnabled) {
        this.roomId = roomId; this.userId = userId; this.userName = userName; this.latitude = latitude; this.longitude = longitude; this.sharingEnabled = sharingEnabled; this.updatedAt = Instant.now();
    }
    void update(double latitude, double longitude, boolean sharingEnabled) { this.latitude = latitude; this.longitude = longitude; this.sharingEnabled = sharingEnabled; this.updatedAt = Instant.now(); }
    void update(double latitude, double longitude, boolean sharingEnabled, String shareLevel, Double speedKmh, String transport) { update(latitude, longitude, sharingEnabled); this.shareLevel = shareLevel; this.speedKmh = speedKmh; this.transport = transport; }
    String userId() { return userId; } String userName() { return userName; } double latitude() { return latitude; } double longitude() { return longitude; } boolean sharingEnabled() { return sharingEnabled; } Instant updatedAt() { return updatedAt; }
}
