package com.gamgam.backend.global.exception;

import org.springframework.http.HttpStatus;

public enum ErrorCode {
    BAD_REQUEST(HttpStatus.BAD_REQUEST, "Invalid request."),
    NOT_FOUND(HttpStatus.NOT_FOUND, "Resource not found."),
    VALIDATION_ERROR(HttpStatus.BAD_REQUEST, "Request validation failed."),
    INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred."),
    APPOINTMENT_NOT_FOUND(HttpStatus.NOT_FOUND, "Appointment not found."),
    ROOM_NOT_FOUND(HttpStatus.NOT_FOUND, "Room not found."),
    UNAUTHENTICATED(HttpStatus.UNAUTHORIZED, "Authentication is required."),
    ROOM_INTEGRATION_UNAVAILABLE(HttpStatus.SERVICE_UNAVAILABLE, "Room membership integration is not configured."),
    NOT_COORDINATING(HttpStatus.CONFLICT, "Appointment is not being coordinated."),
    VOTE_NOT_ALLOWED(HttpStatus.BAD_REQUEST, "This appointment does not coordinate that item."),
    INVALID_OPTION(HttpStatus.BAD_REQUEST, "Option does not exist."),
    DUPLICATE_CANDIDATE(HttpStatus.CONFLICT, "Candidate already exists."),
    ROOM_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You are not a member of this room.");

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
