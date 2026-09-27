package com.gamgam.backend.appointment.vo;

public enum AppointmentTemplate {
    // 모두 정해짐, 시간만 조율, 장소만 조율, 둘 다 조율
    ALL, TIME_ONLY, PLACE_ONLY, BOTH;

    // 템플릿별 시간·장소 조율(투표) 대상 확인 메서드
    public boolean coordinatesTime() {
        return this == TIME_ONLY || this == BOTH;
    }

    public boolean coordinatesPlace() {
        return this == PLACE_ONLY || this == BOTH;
    }

    public boolean isFullyDecided() {
        return this == ALL;
    }
}
