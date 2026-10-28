package com.gamgam.backend.api.v1;

import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest;
import com.gamgam.backend.appointment.dto.JoinAppointmentRequest;
import com.gamgam.backend.appointment.dto.ConfirmAppointmentRequest;
import com.gamgam.backend.appointment.dto.AddTimeOptionRequest;
import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/appointments")
public class AppointmentController {

    private final AppointmentService service;

    @PostMapping
    public ResponseEntity<ApiResponse<AppointmentResponse>> create(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @Valid @RequestBody CreateAppointmentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(service.create(userId, request)));
    }

    @GetMapping
    public ApiResponse<java.util.List<AppointmentResponse>> list(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId) {
        return ApiResponse.ok(service.list(userId));
    }

    @GetMapping("/{id}")
    public ApiResponse<AppointmentResponse> get(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id) {
        return ApiResponse.ok(service.get(userId, id));
    }

    @PostMapping("/join")
    public ApiResponse<AppointmentResponse> join(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @Valid @RequestBody JoinAppointmentRequest request) {
        return ApiResponse.ok(service.join(userId, request.inviteCode()));
    }

    @DeleteMapping("/{id}/members/me")
    public ApiResponse<Void> leave(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id) {
        service.leave(userId, id);
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/{id}/members/{memberId}")
    public ApiResponse<Void> removeMember(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @PathVariable String memberId) {
        service.removeMember(userId, id, memberId);
        return ApiResponse.ok(null);
    }

    @PostMapping("/{id}/votes/time/{optionIndex}")
    public ApiResponse<AppointmentResponse> toggleTimeVote(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @PathVariable int optionIndex) {
        return ApiResponse.ok(service.toggleTimeVote(userId, id, optionIndex));
    }

    @PutMapping("/{id}/votes/place/{optionIndex}")
    public ApiResponse<AppointmentResponse> votePlace(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @PathVariable int optionIndex) {
        return ApiResponse.ok(service.votePlace(userId, id, optionIndex));
    }

    @DeleteMapping("/{id}/votes/place")
    public ApiResponse<AppointmentResponse> clearPlaceVote(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id) {
        return ApiResponse.ok(service.clearPlaceVote(userId, id));
    }

    @PostMapping("/{id}/confirm")
    public ApiResponse<AppointmentResponse> confirm(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @Valid @RequestBody ConfirmAppointmentRequest request) {
        return ApiResponse.ok(service.confirm(userId, id, request));
    }

    @PostMapping("/{id}/options/time")
    public ApiResponse<AppointmentResponse> addTimeOption(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @Valid @RequestBody AddTimeOptionRequest request) {
        return ApiResponse.ok(service.addTimeOption(userId, id, request.time()));
    }

    @PutMapping("/{id}/penalty")
    public ApiResponse<AppointmentResponse> setPenalty(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @Valid @RequestBody CreateAppointmentRequest.PenaltyRequest request) {
        return ApiResponse.ok(service.setPenalty(userId, id, request));
    }

    @PostMapping("/{id}/penalty/agreement")
    public ApiResponse<AppointmentResponse> togglePenaltyAgreement(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id) {
        return ApiResponse.ok(service.togglePenaltyAgreement(userId, id));
    }

    @PostMapping("/{id}/complete")
    public ApiResponse<AppointmentResponse> complete(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id) {
        return ApiResponse.ok(service.complete(userId, id));
    }
}
