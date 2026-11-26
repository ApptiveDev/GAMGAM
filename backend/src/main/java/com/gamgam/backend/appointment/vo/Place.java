package com.gamgam.backend.appointment.vo;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
// 장소 설정값
public record Place(
        @Column(name = "place_name", length = 100) String name,
        @Column(name = "place_latitude") Double latitude,
        @Column(name = "place_longitude") Double longitude,
        @Column(name = "place_address", length=500) String address,
        @Column(name = "place_category", length=100) String category,
        @Column(name = "place_image_url", length=2048) String imageUrl,
        @Column(name = "place_provider_id", length=100) String providerId,
        @Column(name = "place_map_url", length=2048) String mapUrl) {
    public Place(String name,Double latitude,Double longitude) { this(name,latitude,longitude,null,null,null,null,null); }
}
