package com.gamgam.backend.map;

import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import java.util.Comparator;
import java.time.Instant;
import org.springframework.stereotype.Service;

@Service
public class RoomMapService {
    private static final double EARTH_RADIUS_METERS = 6_371_000;
    private final MockRoomRepository roomRepository;
    private final LiveLocationRepository liveLocationRepository;
    private final AppointmentRepository appointmentRepository;

    public RoomMapService(MockRoomRepository roomRepository, LiveLocationRepository liveLocationRepository, AppointmentRepository appointmentRepository) {
        this.roomRepository = roomRepository;
        this.liveLocationRepository = liveLocationRepository;
        this.appointmentRepository = appointmentRepository;
    }

    public RoomMapResponse getMap(String roomId, double latitude, double longitude) {
        var room = roomRepository.findById(roomId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROOM_NOT_FOUND));
        validateSharingWindow(roomId);
        if (room.members().stream().noneMatch(member -> member.id().equals(MockRoomRepository.CURRENT_USER_ID))) {
            throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
        }
        // 1분 이상 GPS 갱신이 없는 참여자는 오래된 위치를 표시하지 않는다.
        Instant freshnessCutoff = Instant.now().minusSeconds(60);
        var participants = liveLocationRepository.findByRoomIdAndSharingEnabledTrue(roomId).stream()
                .filter(location -> location.updatedAt().isAfter(freshnessCutoff))
                .map(location -> {
                    boolean self = location.userId().equals(MockRoomRepository.CURRENT_USER_ID);
                    return new RoomMapResponse.Participant(
                            location.userId(), location.userName(), location.latitude(), location.longitude(),
                            self ? 0 : distance(latitude, longitude, location.latitude(), location.longitude()), self, false, location.updatedAt());
                })
                .sorted(Comparator.comparing(RoomMapResponse.Participant::self).reversed()
                        .thenComparingLong(RoomMapResponse.Participant::distanceMeters)
                        .thenComparing(RoomMapResponse.Participant::id))
                .toList();
        // Room membership, not distance, determines who is visible on this map.
        return new RoomMapResponse(room.id(), room.name(), MockRoomRepository.CURRENT_USER_ID, participants);
    }

    @org.springframework.transaction.annotation.Transactional
    public void updateLocation(String roomId, String userId, LocationUpdateRequest request) {
        var room = roomRepository.findById(roomId).orElseThrow(() -> new BusinessException(ErrorCode.ROOM_NOT_FOUND));
        validateSharingWindow(roomId);
        var member = room.members().stream().filter(item -> item.id().equals(userId)).findFirst()
                .orElseThrow(() -> new BusinessException(ErrorCode.ROOM_ACCESS_DENIED));
        var location = liveLocationRepository.findByRoomIdAndUserId(roomId, userId)
                .orElseGet(() -> new LiveLocation(roomId, member.id(), member.name(), request.latitude(), request.longitude(), request.sharingEnabled()));
        String shareLevel = request.shareLevel() == null ? "BASIC" : request.shareLevel().toUpperCase();
        if (!java.util.Set.of("ALL", "BASIC", "CLOSE", "OFF").contains(shareLevel)) {
            throw new BusinessException(ErrorCode.VALIDATION_ERROR);
        }
        boolean enabled = request.sharingEnabled() && !shareLevel.equals("OFF");
        location.update(request.latitude(), request.longitude(), enabled, shareLevel, request.speedKmh(), request.transport());
        liveLocationRepository.save(location);
    }

    private static long distance(double latitude, double longitude, double otherLatitude, double otherLongitude) {
        double dLat = Math.toRadians(otherLatitude - latitude), dLon = Math.toRadians(otherLongitude - longitude);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) + Math.cos(Math.toRadians(latitude)) * Math.cos(Math.toRadians(otherLatitude)) * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return Math.round(EARTH_RADIUS_METERS * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
    }

    private void validateSharingWindow(String roomId) {
        appointmentRepository.findById(roomId).ifPresent(appointment -> {
            if (appointment.getStatus() != AppointmentStatus.CONFIRMED || appointment.getConfirmedTime() == null) {
                throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
            }
            var policy = appointment.getLocationSharing();
            Instant start = appointment.getConfirmedTime().toInstant().minusSeconds(policy.startMinutesBefore() * 60L);
            Instant end = appointment.getConfirmedTime().toInstant().plusSeconds(policy.maxMinutesAfter() * 60L);
            if (Instant.now().isBefore(start) || Instant.now().isAfter(end)) {
                throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
            }
        });
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
