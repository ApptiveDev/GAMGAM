package com.gamgam.backend.appointment.service;

import com.gamgam.backend.global.config.ShareProperties;
import org.springframework.stereotype.Component;
import org.springframework.web.util.UriComponentsBuilder;

@Component
// appointmentId를 받아서 공유링크 생성
public class ShareLinkGenerator {
    private final ShareProperties shareProperties;

    public ShareLinkGenerator(ShareProperties shareProperties) {
        this.shareProperties = shareProperties;
    }

    public String create(String appointmentId) {
        return UriComponentsBuilder.fromUriString(shareProperties.baseUrl())
                .path("/appointments/{id}")
                .buildAndExpand(appointmentId)
                .toUriString();
    }
}
