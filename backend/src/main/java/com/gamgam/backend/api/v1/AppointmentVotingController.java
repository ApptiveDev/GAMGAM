package com.gamgam.backend.api.v1;

import com.gamgam.backend.appointment.dto.AppointmentVotingResponse;
import com.gamgam.backend.appointment.service.AppointmentVotingService;
import com.gamgam.backend.global.auth.CurrentUserProvider;
import com.gamgam.backend.global.response.ApiResponse;
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
}
