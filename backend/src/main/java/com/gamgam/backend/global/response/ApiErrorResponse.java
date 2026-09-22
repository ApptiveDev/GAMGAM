package com.gamgam.backend.global.response;

import java.util.Map;

public record ApiErrorResponse(boolean success, String code, String message, Map<String, String> fieldErrors) {

    public static ApiErrorResponse of(String code, String message) {
        return new ApiErrorResponse(false, code, message, Map.of());
    }
}
