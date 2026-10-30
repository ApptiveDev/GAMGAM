package com.gamgam.backend.global.exception;

import org.springframework.http.HttpStatus;

public enum ErrorCode {
    BAD_REQUEST(HttpStatus.BAD_REQUEST, "Invalid request."),
    NOT_FOUND(HttpStatus.NOT_FOUND, "Resource not found."),
    VALIDATION_ERROR(HttpStatus.BAD_REQUEST, "Request validation failed."),
    INTERNAL_SERVER_ERROR(HttpStatus.INTERNAL_SERVER_ERROR, "An unexpected error occurred."),
    EMAIL_ALREADY_EXISTS(HttpStatus.CONFLICT, "An account with this email already exists."),
    INVALID_CREDENTIALS(HttpStatus.UNAUTHORIZED, "Email or password is incorrect."),
    AUTHENTICATION_REQUIRED(HttpStatus.UNAUTHORIZED, "Authentication is required."),
    INVALID_TOKEN(HttpStatus.UNAUTHORIZED, "Access token is invalid or expired."),
    USER_NOT_FOUND(HttpStatus.NOT_FOUND, "User not found."),
    APPOINTMENT_NOT_FOUND(HttpStatus.NOT_FOUND, "Appointment not found."),
    APPOINTMENT_ACCESS_DENIED(HttpStatus.FORBIDDEN, "You do not have access to this appointment."),
    APPOINTMENT_HOST_ONLY(HttpStatus.FORBIDDEN, "Only the appointment host can perform this action."),
    ALREADY_JOINED(HttpStatus.CONFLICT, "You have already joined this appointment."),
    INVALID_INVITE_CODE(HttpStatus.NOT_FOUND, "Invite code is invalid."),
    INVALID_VOTE_OPTION(HttpStatus.BAD_REQUEST, "Vote option is invalid."),
    HOST_CANNOT_LEAVE(HttpStatus.BAD_REQUEST, "The appointment host cannot leave the appointment."),
    MEMBER_NOT_FOUND(HttpStatus.NOT_FOUND, "Appointment member not found."),
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
