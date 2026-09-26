package com.gamgam.backend.global.exception;

import org.springframework.http.HttpStatus;

public enum ErrorCode {
    BAD_REQUEST(HttpStatus.BAD_REQUEST, "Invalid request."),
    VALIDATION_ERROR(HttpStatus.BAD_REQUEST, "Request validation failed."),
    ROOM_NOT_FOUND(HttpStatus.NOT_FOUND, "Room not found."),
    ROOM_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You are not a member of this room."),
    INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred.");

    private final HttpStatus status;
    private final String message;

    ErrorCode(HttpStatus status, String message) {
        this.status = status;
        this.message = message;
    }

    public HttpStatus status() {
        return status;
    }

    public String message() {
        return message;
    }
}
