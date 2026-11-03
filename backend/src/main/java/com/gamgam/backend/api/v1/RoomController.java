package com.gamgam.backend.api.v1;

import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import com.gamgam.backend.room.CreateRoomRequest;
import com.gamgam.backend.room.RoomResponse;
import com.gamgam.backend.room.RoomService;
import jakarta.validation.Valid;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/rooms")
public class RoomController {
    private final RoomService service;

    @PostMapping
    public ResponseEntity<ApiResponse<RoomResponse>> create(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @Valid @RequestBody CreateRoomRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(service.create(userId, request)));
    }

    @GetMapping
    public ApiResponse<List<RoomResponse>> list(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId) {
        return ApiResponse.ok(service.list(userId));
    }

    @GetMapping("/{roomId}")
    public ApiResponse<RoomResponse> get(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @PathVariable String roomId) {
        return ApiResponse.ok(service.get(userId, roomId));
    }
}
