package com.gamgam.backend.map;

import java.util.List;

public record RoomMapResponse(String roomId, String roomName, String currentUserId, List<Participant> participants) {
    public record Participant(
            String id, String name, double latitude, double longitude,
            long distanceMeters, boolean self, boolean mock
    ) {
    }
}
