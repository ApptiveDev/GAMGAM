package com.gamgam.backend.global.util;

import static org.assertj.core.api.Assertions.assertThat;

import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import org.junit.jupiter.api.Test;

class KstTimeConverterTests {

    private static final OffsetDateTime KST_TIME = OffsetDateTime.parse("2030-01-01T19:00:00+09:00");

    @Test
    void 어떤_오프셋이든_UTC로_정규화하고_시각은_유지한다() {
        var pst = OffsetDateTime.parse("2030-01-01T02:00:00-08:00");

        var utc = KstTimeConverter.toUtc(pst);

        assertThat(utc.getOffset()).isEqualTo(ZoneOffset.UTC);
        assertThat(utc.toInstant()).isEqualTo(pst.toInstant());
    }

    @Test
    void UTC를_KST로_바꾼다() {
        var kst = KstTimeConverter.toKst(OffsetDateTime.parse("2030-01-01T10:00:00Z"));

        assertThat(kst.getOffset()).isEqualTo(KstTimeConverter.KST);
        assertThat(kst.getHour()).isEqualTo(19);
    }

    @Test
    void KST_UTC_왕복해도_같은_시각이다() {
        var roundTrip = KstTimeConverter.toKst(KstTimeConverter.toUtc(KST_TIME));

        assertThat(roundTrip).isEqualTo(KST_TIME);
    }

    @Test
    void null은_null로_돌려준다() {
        assertThat(KstTimeConverter.toUtc((OffsetDateTime) null)).isNull();
        assertThat(KstTimeConverter.toKst((OffsetDateTime) null)).isNull();
        assertThat(KstTimeConverter.toUtc((List<OffsetDateTime>) null)).isNull();
        assertThat(KstTimeConverter.toKst((List<OffsetDateTime>) null)).isNull();
    }

    @Test
    void 리스트도_순서를_유지하며_변환한다() {
        var list = List.of(KST_TIME, KST_TIME.plusHours(1));

        var utc = KstTimeConverter.toUtc(list);

        assertThat(utc).allMatch(t -> t.getOffset().equals(ZoneOffset.UTC));
        assertThat(utc.get(1).toInstant()).isEqualTo(list.get(1).toInstant());
    }
}
