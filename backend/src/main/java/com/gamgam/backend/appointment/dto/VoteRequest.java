package com.gamgam.backend.appointment.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import java.util.Set;

/** 시간·장소 모두 복수 선택. 빈 집합은 해당 종류의 내 투표를 모두 취소한다. */
public record VoteRequest(@NotNull Set<@NotNull @Min(0) Integer> optionIndexes) {
}
