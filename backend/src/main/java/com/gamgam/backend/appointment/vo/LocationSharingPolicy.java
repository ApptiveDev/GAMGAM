package com.gamgam.backend.appointment.vo;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
// 위치 공유 시간 설정값
public record LocationSharingPolicy(
        // 약속 시간 n분 전부터 위치 공유 시작
        @Column(name = "location_start_minutes_before", nullable = false) int startMinutesBefore,
        // 약속 시간 n분 후까지 위치 공유 유지 (이후 자동 종료)
        @Column(name = "location_max_minutes_after", nullable = false) int maxMinutesAfter) {

    public static final int DEFAULT_START_MINUTES_BEFORE = 30;
    public static final int DEFAULT_MAX_MINUTES_AFTER = 30;

    public static LocationSharingPolicy defaults() {
        return new LocationSharingPolicy(DEFAULT_START_MINUTES_BEFORE, DEFAULT_MAX_MINUTES_AFTER);
    }
}
