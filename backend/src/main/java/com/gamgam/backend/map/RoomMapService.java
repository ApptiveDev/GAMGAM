package com.gamgam.backend.map;

import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.user.repository.UserRepository;
import java.time.Instant;
import java.util.Comparator;
import org.springframework.stereotype.Service;

@Service
public class RoomMapService {
    private static final double EARTH_RADIUS_METERS = 6_371_000;

    private final LiveLocationRepository liveLocationRepository;
    private final AppointmentRepository appointmentRepository;
    private final AppointmentMemberRepository memberRepository;
    private final UserRepository userRepository;

    public RoomMapService(LiveLocationRepository liveLocationRepository,
                          AppointmentRepository appointmentRepository,
                          AppointmentMemberRepository memberRepository,
                          UserRepository userRepository) {
        this.liveLocationRepository = liveLocationRepository;
        this.appointmentRepository = appointmentRepository;
        this.memberRepository = memberRepository;
        this.userRepository = userRepository;
    }

    public RoomMapResponse getMap(String roomId, String currentUserId, double latitude, double longitude) {
        var appointment = findAppointment(roomId);
        requireMember(roomId, currentUserId);
        validateSharingWindow(appointment);

        Instant freshnessCutoff = Instant.now().minusSeconds(60);
        var participants = liveLocationRepository.findByRoomIdAndSharingEnabledTrue(roomId).stream()
                .filter(location -> location.updatedAt().isAfter(freshnessCutoff))
                .map(location -> {
                    boolean self = location.userId().equals(currentUserId);
                    return new RoomMapResponse.Participant(
                            location.userId(), location.userName(), location.latitude(), location.longitude(),
                            self ? 0 : distance(latitude, longitude, location.latitude(), location.longitude()),
                            self, false, location.updatedAt());
                })
                .sorted(Comparator.comparing(RoomMapResponse.Participant::self).reversed()
                        .thenComparingLong(RoomMapResponse.Participant::distanceMeters)
                        .thenComparing(RoomMapResponse.Participant::id))
                .toList();
        return new RoomMapResponse(appointment.getId(), appointment.getName(), currentUserId, participants);
    }

    @org.springframework.transaction.annotation.Transactional
    public void updateLocation(String roomId, String userId, LocationUpdateRequest request) {
        var appointment = findAppointment(roomId);
        requireMember(roomId, userId);
        validateSharingWindow(appointment);
        var user = userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
        var location = liveLocationRepository.findByRoomIdAndUserId(roomId, userId)
                .orElseGet(() -> new LiveLocation(roomId, userId, user.getName(),
                        request.latitude(), request.longitude(), request.sharingEnabled()));
        String shareLevel = request.shareLevel() == null ? "BASIC" : request.shareLevel().toUpperCase();
        if (!java.util.Set.of("ALL", "BASIC", "CLOSE", "OFF").contains(shareLevel)) {
            throw new BusinessException(ErrorCode.VALIDATION_ERROR);
        }
        boolean enabled = request.sharingEnabled() && !shareLevel.equals("OFF");
        location.update(request.latitude(), request.longitude(), enabled,
                shareLevel, request.speedKmh(), request.transport());
        liveLocationRepository.save(location);
    }

    private com.gamgam.backend.appointment.entity.Appointment findAppointment(String roomId) {
        return appointmentRepository.findById(roomId)
                .orElseThrow(() -> new BusinessException(ErrorCode.ROOM_NOT_FOUND));
    }

    private void requireMember(String roomId, String userId) {
        if (!memberRepository.existsByAppointmentIdAndUserId(roomId, userId)) {
            throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
        }
    }

    private static void validateSharingWindow(com.gamgam.backend.appointment.entity.Appointment appointment) {
        if (appointment.getStatus() != AppointmentStatus.CONFIRMED || appointment.getConfirmedTime() == null) {
            throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
        }
        var policy = appointment.getLocationSharing();
        Instant start = appointment.getConfirmedTime().toInstant().minusSeconds(policy.startMinutesBefore() * 60L);
        Instant end = appointment.getConfirmedTime().toInstant().plusSeconds(policy.maxMinutesAfter() * 60L);
        if (Instant.now().isBefore(start) || Instant.now().isAfter(end)) {
            throw new BusinessException(ErrorCode.ROOM_ACCESS_DENIED);
        }
    }

    private static long distance(double latitude, double longitude, double otherLatitude, double otherLongitude) {
        double dLat = Math.toRadians(otherLatitude - latitude);
        double dLon = Math.toRadians(otherLongitude - longitude);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(latitude)) * Math.cos(Math.toRadians(otherLatitude))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return Math.round(EARTH_RADIUS_METERS * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a)));
    }
}
