package com.gamgam.backend.api.v1;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PlaceRequest;
import com.gamgam.backend.appointment.dto.RegardlessVoteRequest;
import com.gamgam.backend.appointment.dto.TimeCandidateRequest;
import com.gamgam.backend.appointment.dto.VoteRequest;
import com.gamgam.backend.appointment.service.AppointmentVotingService;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/appointments/{id}")
public class AppointmentVotingController {
    private final AppointmentVotingService service;

    @GetMapping("/votes")
    public ApiResponse<AppointmentVotingResponse> get(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id) {
        return ApiResponse.ok(service.get(id, userId));
    }

    @PutMapping("/votes/time")
    public ApiResponse<AppointmentVotingResponse> time(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @Valid @RequestBody VoteRequest request) {
        return ApiResponse.ok(service.voteTime(id, userId, request.optionIndexes()));
    }

    @PutMapping("/votes/place")
    public ApiResponse<AppointmentVotingResponse> place(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @Valid @RequestBody VoteRequest request) {
        return ApiResponse.ok(service.votePlace(id, userId, request.optionIndexes()));
    }

    @PutMapping("/votes/regardless")
    public ApiResponse<AppointmentVotingResponse> regardless(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @Valid @RequestBody RegardlessVoteRequest request) {
        return ApiResponse.ok(service.participateRegardless(id, userId, request.selected()));
    }

    @PostMapping("/time-candidates")
    public ApiResponse<AppointmentVotingResponse> addTime(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @Valid @RequestBody TimeCandidateRequest request) {
        return ApiResponse.ok(service.addTimeCandidate(id, userId, request));
    }

    @PostMapping("/place-candidates")
    public ApiResponse<AppointmentVotingResponse> addPlace(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String id,
            @Valid @RequestBody PlaceRequest request) {
        return ApiResponse.ok(service.addPlaceCandidate(id, userId, request));
    }
}
