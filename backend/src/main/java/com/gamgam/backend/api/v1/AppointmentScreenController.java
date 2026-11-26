package com.gamgam.backend.api.v1;

import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.service.AppointmentScreenService;
import com.gamgam.backend.appointment.service.AppointmentScreenService.*;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1")
public class AppointmentScreenController {
    private final AppointmentScreenService service;
    @GetMapping({"/home", "/rooms/{roomId}/dashboard"})
    public ApiResponse<Screen> list(@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,
            @PathVariable(required=false) String roomId, @RequestParam(defaultValue="ALL") Filter filter,
            @RequestParam(defaultValue="NEWEST") Sort sort, @RequestParam(defaultValue="") String query,
            @RequestParam(defaultValue="0") int page, @RequestParam(defaultValue="20") int size) {
        return ApiResponse.ok(service.list(user, roomId, filter, sort, query, page, size));
    }
    @PutMapping("/appointments/{id}/appearance")
    public ApiResponse<AppointmentResponse> decorate(@PathVariable String id,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user, @Valid @RequestBody Appearance r) {
        return ApiResponse.ok(service.decorate(id, user, r));
    }
}
