package com.gamgam.backend.map;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import java.util.Comparator;
import org.springframework.stereotype.Service;

@Service
public class RoomMapService {
    private static final double EARTH_RADIUS_METERS = 6_371_000;
    private final MockRoomRepository roomRepository;

    public RoomMapService(MockRoomRepository roomRepository) {
        this.roomRepository = roomRepository;
    }

    public RoomMapResponse getMap(String roomId, double latitude, double longitude) {
        var room = roomRepository.findById(roomId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROOM_NOT_FOUND));
        if (room.members().stream().noneMatch(member -> member.id().equals(MockRoomRepository.CURRENT_USER_ID))) {
            throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
        }
        var participants = room.members().stream()
                .map(member -> {
                    boolean self = member.id().equals(MockRoomRepository.CURRENT_USER_ID);
                    var location = self ? new Location(latitude, longitude)
                            : offset(latitude, longitude, member.distanceMeters(), member.bearingDegrees());
                    return new RoomMapResponse.Participant(
                            member.id(), member.name(), location.latitude(), location.longitude(),
                            self ? 0 : Math.round(member.distanceMeters()), self, !self);
                })
                .sorted(Comparator.comparing(RoomMapResponse.Participant::self).reversed()
                        .thenComparingLong(RoomMapResponse.Participant::distanceMeters)
                        .thenComparing(RoomMapResponse.Participant::id))
                .toList();
        // Room membership, not distance, determines who is visible on this map.
        return new RoomMapResponse(room.id(), room.name(), MockRoomRepository.CURRENT_USER_ID, participants);
    }

    private static Location offset(double latitude, double longitude, double meters, double bearingDegrees) {
        // Rotate a unit position vector towards a tangent direction; also valid at the poles.
        double lat = Math.toRadians(latitude);
        double lon = Math.toRadians(longitude);
        double bearing = Math.toRadians(bearingDegrees);
        double angle = meters / EARTH_RADIUS_METERS;
        double north = Math.cos(bearing) * Math.sin(angle);
        double east = Math.sin(bearing) * Math.sin(angle);
        double x = Math.cos(angle) * Math.cos(lat) * Math.cos(lon)
                - north * Math.sin(lat) * Math.cos(lon) - east * Math.sin(lon);
        double y = Math.cos(angle) * Math.cos(lat) * Math.sin(lon)
                - north * Math.sin(lat) * Math.sin(lon) + east * Math.cos(lon);
        double z = Math.cos(angle) * Math.sin(lat) + north * Math.cos(lat);
        return new Location(Math.toDegrees(Math.atan2(z, Math.hypot(x, y))), Math.toDegrees(Math.atan2(y, x)));
    }

    private record Location(double latitude, double longitude) {
    }
}
