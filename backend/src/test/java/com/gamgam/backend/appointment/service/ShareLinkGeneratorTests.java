package com.gamgam.backend.appointment.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamgam.backend.global.config.ShareProperties;
import org.junit.jupiter.api.Test;

class ShareLinkGeneratorTests {

    @Test
    void baseUrl_뒤에_appointments_id를_붙인다() {
        var generator = new ShareLinkGenerator(new ShareProperties("http://localhost:3000"));

        assertThat(generator.create("abc-123")).isEqualTo("http://localhost:3000/appointments/abc-123");
    }

    @Test
    void baseUrl에_경로가_있어도_이어_붙인다() {
        var generator = new ShareLinkGenerator(new ShareProperties("https://app.example.com/gamgam"));

        assertThat(generator.create("abc-123")).isEqualTo("https://app.example.com/gamgam/appointments/abc-123");
    }
}
