package com.gamgam.backend.api.v1;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.dto.VoteRequest;
import com.gamgam.backend.appointment.dto.RegardlessVoteRequest;
import com.gamgam.backend.appointment.service.AppointmentVotingService;
import com.gamgam.backend.global.auth.CurrentUserProvider;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/appointments/{id}")
public class AppointmentVotingController {
    private final AppointmentVotingService service;
    private final CurrentUserProvider currentUser;

    @GetMapping("/votes")
    public ApiResponse<AppointmentVotingResponse> get(@PathVariable String id) {
        return ApiResponse.ok(service.get(id, currentUser.userId()));
    }

    // 시간 투표
    @PutMapping("/votes/time")
    public ApiResponse<AppointmentVotingResponse> time(@PathVariable String id, @Valid @RequestBody VoteRequest request) {
        return ApiResponse.ok(service.voteTime(id, currentUser.userId(), request.optionIndexes()));
    }

    // 장소 투표
    @PutMapping("/votes/place")
    public ApiResponse<AppointmentVotingResponse> place(@PathVariable String id, @Valid @RequestBody VoteRequest request) {
        return ApiResponse.ok(service.votePlace(id, currentUser.userId(), request.optionIndexes()));
    }

    // 상관없이 참여 선택
    @PutMapping("/votes/regardless")
    public ApiResponse<AppointmentVotingResponse> regardless(@PathVariable String id,
            @Valid @RequestBody RegardlessVoteRequest request) {
        return ApiResponse.ok(service.participateRegardless(id, currentUser.userId(), request.selected()));
    }
}
