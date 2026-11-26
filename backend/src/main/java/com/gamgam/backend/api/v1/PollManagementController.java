package com.gamgam.backend.api.v1;

import com.gamgam.backend.appointment.dto.*;
import com.gamgam.backend.appointment.service.PollManagementService;
import com.gamgam.backend.appointment.vo.VoteType;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/appointments/{id}")
public class PollManagementController {
    private final PollManagementService service;
    @PutMapping("/polls/{type}")
    public ApiResponse<AppointmentVotingResponse> configure(@PathVariable String id, @PathVariable VoteType type,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user, @Valid @RequestBody PollSettingsRequest r) {
        return ApiResponse.ok(service.configure(id, user, type, r));
    }
    @PostMapping("/polls/{type}/close")
    public ApiResponse<AppointmentVotingResponse> close(@PathVariable String id, @PathVariable VoteType type,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) { return ApiResponse.ok(service.close(id, user, type)); }
    @PostMapping("/polls/{type}/gift/draw")
    public ApiResponse<AppointmentVotingResponse> award(@PathVariable String id, @PathVariable VoteType type,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) { return ApiResponse.ok(service.award(id, user, type)); }
    @PutMapping("/time-candidates/{candidateId}")
    public ApiResponse<AppointmentVotingResponse> time(@PathVariable String id, @PathVariable String candidateId,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user, @Valid @RequestBody TimeCandidateRequest r) {
        return ApiResponse.ok(service.editTime(id, user, candidateId, r));
    }
    @PutMapping("/place-candidates/{candidateId}")
    public ApiResponse<AppointmentVotingResponse> place(@PathVariable String id, @PathVariable String candidateId,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user, @Valid @RequestBody CreateAppointmentRequest.PlaceRequest r) {
        return ApiResponse.ok(service.editPlace(id, user, candidateId, r));
    }
    @DeleteMapping("/time-candidates/{candidateId}")
    public ApiResponse<AppointmentVotingResponse> deleteTime(@PathVariable String id, @PathVariable String candidateId,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) { return ApiResponse.ok(service.delete(id, user, VoteType.TIME, candidateId)); }
    @DeleteMapping("/place-candidates/{candidateId}")
    public ApiResponse<AppointmentVotingResponse> deletePlace(@PathVariable String id, @PathVariable String candidateId,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) { return ApiResponse.ok(service.delete(id, user, VoteType.PLACE, candidateId)); }
}
