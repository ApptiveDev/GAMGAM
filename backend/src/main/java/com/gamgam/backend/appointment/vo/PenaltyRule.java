package com.gamgam.backend.appointment.vo;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;

@Embeddable
// 벌칙 규칙 설정값
public record PenaltyRule(
        @Column(name = "penalty_description", length = 100) String description,
        @Enumerated(EnumType.STRING) @Column(name = "late_threshold_min") LateThreshold lateThresholdMin,
        @Enumerated(EnumType.STRING) @Column(name = "penalty_target") PenaltyTarget target) {
}
