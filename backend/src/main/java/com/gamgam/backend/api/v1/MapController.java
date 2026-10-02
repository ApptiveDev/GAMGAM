package com.gamgam.backend.api.v1;

import com.gamgam.backend.global.response.ApiResponse;
import com.gamgam.backend.map.LocationUpdateRequest;
import com.gamgam.backend.map.RoomMapRequest;
import com.gamgam.backend.map.RoomMapResponse;
import com.gamgam.backend.map.RoomMapService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/rooms")
public class MapController {

    private final RoomMapService roomMapService;

    public MapController(RoomMapService roomMapService) {
        this.roomMapService = roomMapService;
    }

    @GetMapping("/{roomId}/map")
    public ApiResponse<RoomMapResponse> roomMap(@PathVariable String roomId, @Valid @ModelAttribute RoomMapRequest request) {
        return ApiResponse.ok(roomMapService.getMap(roomId, request.latitude(), request.longitude()));
    }

    @PutMapping("/{roomId}/location")
    public ApiResponse<Void> updateLocation(@PathVariable String roomId, @RequestHeader(value = "X-User-Id", defaultValue = "u-yeeun") String userId, @Valid @RequestBody LocationUpdateRequest request) {
        roomMapService.updateLocation(roomId, userId, request);
        return ApiResponse.ok(null);
    }
}
