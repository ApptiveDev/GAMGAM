package com.gamgam.backend.auth.security;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamgam.backend.user.entity.User;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.LinkedHashMap;
import java.util.Map;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.stereotype.Component;

@Component
public class JwtTokenProvider {

    private static final Base64.Encoder BASE64_URL = Base64.getUrlEncoder().withoutPadding();
    private static final String HEADER = BASE64_URL.encodeToString(
            "{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));

    private final JwtProperties properties;
    private final ObjectMapper objectMapper = new ObjectMapper();

    public JwtTokenProvider(JwtProperties properties) {
        this.properties = properties;
    }

    public AccessToken create(User user) {
        Instant issuedAt = Instant.now();
        Instant expiresAt = issuedAt.plusSeconds(properties.expirationSeconds());
        Map<String, Object> claims = new LinkedHashMap<>();
        claims.put("sub", user.getId());
        claims.put("email", user.getEmail());
        claims.put("iat", issuedAt.getEpochSecond());
        claims.put("exp", expiresAt.getEpochSecond());

        try {
            String payload = BASE64_URL.encodeToString(objectMapper.writeValueAsBytes(claims));
            String unsignedToken = HEADER + "." + payload;
            return new AccessToken(unsignedToken + "." + sign(unsignedToken), properties.expirationSeconds());
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Could not create access token.", exception);
        }
    }

    private String sign(String value) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(properties.secret().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return BASE64_URL.encodeToString(mac.doFinal(value.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception exception) {
            throw new IllegalStateException("JWT signing is unavailable.", exception);
        }
    }

    public record AccessToken(String value, long expiresInSeconds) {
    }
}
