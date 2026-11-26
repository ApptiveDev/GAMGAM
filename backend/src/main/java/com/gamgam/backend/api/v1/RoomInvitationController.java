package com.gamgam.backend.api.v1;

import com.gamgam.backend.room.*;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/rooms")
public class RoomInvitationController {
    private final RoomInvitationService service;
    @GetMapping("/{id}/invite")
    public ApiResponse<RoomInvitationService.Invitation> invite(@PathVariable String id,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) { return ApiResponse.ok(service.invite(id, user, false)); }
    @PostMapping("/{id}/invite/rotate")
    public ApiResponse<RoomInvitationService.Invitation> rotate(@PathVariable String id,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) { return ApiResponse.ok(service.invite(id, user, true)); }
    @PostMapping("/join")
    public ApiResponse<RoomResponse> join(@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,
            @Valid @RequestBody RoomInvitationService.JoinRequest r) { return ApiResponse.ok(service.join(user, r.inviteCode())); }
    @GetMapping("/{id}/members")
    public ApiResponse<java.util.List<RoomInvitationService.Member>> members(@PathVariable String id,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) { return ApiResponse.ok(service.members(id, user)); }
    @PatchMapping("/{id}")
    public ApiResponse<RoomResponse> rename(@PathVariable String id, @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,
            @Valid @RequestBody RoomInvitationService.UpdateRoom r) { return ApiResponse.ok(service.rename(id, user, r)); }
}
