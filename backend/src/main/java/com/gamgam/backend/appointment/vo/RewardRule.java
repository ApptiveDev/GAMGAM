package com.gamgam.backend.appointment.vo;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

@Embeddable
// 보상 규칙 설정값
public record RewardRule(
        @Column(name = "reward_description", length = 100) String description) {
}
