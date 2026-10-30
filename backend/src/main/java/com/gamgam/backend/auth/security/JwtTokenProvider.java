package com.gamgam.backend.auth.security;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
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

    public String verifyAndGetUserId(String token) {
        try {
            String[] parts = token.split("\\.", -1);
            if (parts.length != 3 || !HEADER.equals(parts[0])) {
                throw invalidToken();
            }
            String unsignedToken = parts[0] + "." + parts[1];
            byte[] expected = Base64.getUrlDecoder().decode(sign(unsignedToken));
            byte[] actual = Base64.getUrlDecoder().decode(parts[2]);
            if (!java.security.MessageDigest.isEqual(expected, actual)) {
                throw invalidToken();
            }

            @SuppressWarnings("unchecked")
            Map<String, Object> claims = objectMapper.readValue(
                    Base64.getUrlDecoder().decode(parts[1]), Map.class);
            Object subject = claims.get("sub");
            Object expiration = claims.get("exp");
            if (!(subject instanceof String userId) || userId.isBlank()
                    || !(expiration instanceof Number exp)
                    || Instant.now().getEpochSecond() >= exp.longValue()) {
                throw invalidToken();
            }
            return userId;
        } catch (BusinessException exception) {
            throw exception;
        } catch (Exception exception) {
            throw invalidToken();
        }
    }

    private static BusinessException invalidToken() {
        return new BusinessException(ErrorCode.INVALID_TOKEN);
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
