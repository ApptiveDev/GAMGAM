package com.gamgam.backend.appointment.vo;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
// 장소 설정값
public record Place(
        @Column(name = "place_name", length = 100) String name,
        @Column(name = "place_latitude") Double latitude,
        @Column(name = "place_longitude") Double longitude) {
}
