package com.gamgam.backend.api.v1;

import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest;
import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.global.auth.CurrentUserProvider;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1")
public class AppointmentController {

    private final AppointmentService service;
    private final CurrentUserProvider currentUser;

    @PostMapping("/rooms/{roomId}/appointments")
    public ResponseEntity<ApiResponse<AppointmentResponse>> create(@PathVariable String roomId,
            @Valid @RequestBody CreateAppointmentRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok(service.create(roomId, currentUser.userId(), request)));
    }

    @GetMapping("/rooms/{roomId}/appointments")
    public ApiResponse<java.util.List<AppointmentResponse>> list(@PathVariable String roomId) {
        return ApiResponse.ok(service.list(roomId, currentUser.userId()));
    }

    @GetMapping("/appointments/{id}")
    public ApiResponse<AppointmentResponse> get(@PathVariable String id) {
        return ApiResponse.ok(service.get(id, currentUser.userId()));
    }
}
