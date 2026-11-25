package com.gamgam.backend.api.v1;
import com.gamgam.backend.map.*;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController @RequiredArgsConstructor @RequestMapping("/api/v1")
public class AttendanceController {
    private final AttendanceService service;
    private final RoomMapService maps;
    @GetMapping("/appointments/{id}/attendance")
    public ApiResponse<AttendanceService.Summary> get(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {return ApiResponse.ok(service.get(id,user));}
    @PutMapping("/appointments/{id}/attendance/me")
    public ApiResponse<AttendanceService.Summary> update(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,
            @Valid @RequestBody AttendanceService.StatusRequest r) {return ApiResponse.ok(service.update(id,user,r));}
    @DeleteMapping("/appointments/{id}/location")
    public ApiResponse<Void> disable(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {service.disableSharing(id,user);return ApiResponse.ok(null);}
    @PutMapping("/appointments/{id}/location")
    public ApiResponse<Void> location(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,
            @Valid @RequestBody LocationUpdateRequest r) {maps.updateLocation(id,user,r);return ApiResponse.ok(null);}
    @GetMapping("/appointments/{id}/map")
    public ApiResponse<RoomMapResponse> map(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,
            @Valid @ModelAttribute RoomMapRequest r) {return ApiResponse.ok(maps.getMap(id,user,r.latitude(),r.longitude()));}
    @PostMapping("/appointments/{id}/members/{memberId}/poke")
    public ApiResponse<AttendanceService.Notification> poke(@PathVariable String id,@PathVariable String memberId,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {return ApiResponse.ok(service.poke(id,user,memberId));}
    @GetMapping("/notifications")
    public ApiResponse<java.util.List<AttendanceService.Notification>> inbox(@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {return ApiResponse.ok(service.inbox(user));}
    @PutMapping("/notifications/{id}/read")
    public ApiResponse<AttendanceService.Notification> read(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {return ApiResponse.ok(service.read(user,id));}
}
