package com.gamgam.backend.global.util;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;


// 요청(다양한 오프셋 가능) → 저장(UTC 고정), 저장(UTC) → 응답(KST 고정) 변환을 담당한다.
public final class KstTimeConverter {

    public static final ZoneOffset KST = ZoneOffset.of("+09:00");

    private KstTimeConverter() {
    }

    // 클라이언트가 어떤 오프셋으로 보내든, 저장 전 UTC로 정규화한다.
    public static OffsetDateTime toUtc(OffsetDateTime time) {
        return time == null ? null : time.withOffsetSameInstant(ZoneOffset.UTC);
    }

    public static List<OffsetDateTime> toUtc(List<OffsetDateTime> times) {
        return times == null ? null : times.stream().map(KstTimeConverter::toUtc).toList();
    }

    // DB에 저장된 UTC 값을 응답 직전에 KST로 변환한다.
    public static OffsetDateTime toKst(OffsetDateTime time) {
        return time == null ? null : time.withOffsetSameInstant(KST);
    }

    public static List<OffsetDateTime> toKst(List<OffsetDateTime> times) {
        return times == null ? null : times.stream().map(KstTimeConverter::toKst).toList();
    }
}
