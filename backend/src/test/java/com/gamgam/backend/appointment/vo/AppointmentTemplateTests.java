package com.gamgam.backend.appointment.vo;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

class AppointmentTemplateTests {

    @ParameterizedTest
    @CsvSource({
            "ALL,        false, false, true",
            "TIME_ONLY,  true,  false, false",
            "PLACE_ONLY, false, true,  false",
            "BOTH,       true,  true,  false"
    })
    void 템플릿별_조율_대상(AppointmentTemplate template, boolean time, boolean place, boolean fullyDecided) {
        assertThat(template.coordinatesTime()).isEqualTo(time);
        assertThat(template.coordinatesPlace()).isEqualTo(place);
        assertThat(template.isFullyDecided()).isEqualTo(fullyDecided);
    }
}
