package com.gamgam.backend.appointment.vo;

public enum LateThreshold {
    // 지각 기준
    // 5분, 10분, 15분
    FIVE(5), TEN(10), FIFTEEN(15);

    private final int minutes;

    LateThreshold(int minutes) {
        this.minutes = minutes;
    }

    public int minutes() {
        return minutes;
    }
}
