package com.gamgam.backend.appointment.service;

import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.global.exception.*;
import com.gamgam.backend.room.RoomAccess;
import jakarta.validation.constraints.*;
import java.time.*;
import java.util.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly=true)
public class AppointmentScreenService {
    private final AppointmentRepository repository;
    private final AppointmentService appointments;
    private final RoomAccess rooms;
    private final com.gamgam.backend.media.MediaService media;
    public enum Filter { ALL, UPCOMING, COMPLETED }
    public enum Sort { NEWEST, TIME, NAME }
    public record Appearance(@Size(max=2048) @Pattern(regexp="https?://[^\\s]+", message="Use an http(s) image URL") String coverImageUrl,
            @Size(max=1000) String cardText, @Size(max=30) String cardStyle) {}
    public record Screen(Instant serverTime, AppointmentResponse nextAppointment, Long secondsUntilNext,
            long totalCount, long upcomingCount, long completedCount, int page, int size, List<AppointmentResponse> items) {}

    public Screen list(String user, String room, Filter filter, Sort sort, String query, int page, int size) {
        if (page < 0 || size < 1 || size > 100 || query.length() > 100) throw new BusinessException(ErrorCode.BAD_REQUEST);
        var all = room == null ? appointments.list(user) : appointments.list(room, user);
        var now = Instant.now();
        var next = all.stream().filter(a -> a.status() == AppointmentStatus.CONFIRMED && a.confirmedTime() != null
                && !a.confirmedTime().toInstant().isBefore(now)).min(Comparator.comparing(AppointmentResponse::confirmedTime)).orElse(null);
        Comparator<AppointmentResponse> order = switch (sort) {
            case TIME -> Comparator.comparing(AppointmentResponse::confirmedTime, Comparator.nullsLast(Comparator.naturalOrder()));
            case NAME -> Comparator.comparing(AppointmentResponse::name);
            default -> Comparator.comparing(AppointmentResponse::createdAt).reversed();
        };
        var matching = all.stream().filter(a -> filter == Filter.ALL || (filter == Filter.COMPLETED) == (a.status() == AppointmentStatus.COMPLETED))
                .filter(a -> a.name().toLowerCase(Locale.ROOT).contains(query.strip().toLowerCase(Locale.ROOT)))
                .sorted(order.thenComparing(AppointmentResponse::id)).toList();
        long completed = all.stream().filter(a -> a.status() == AppointmentStatus.COMPLETED).count();
        return new Screen(now, next, next == null ? null : Duration.between(now, next.confirmedTime().toInstant()).getSeconds(),
                matching.size(), all.size()-completed, completed, page, size, matching.stream().skip((long)page*size).limit(size).toList());
    }
    @Transactional
    public AppointmentResponse decorate(String id, String user, Appearance r) {
        var a = repository.findByIdForUpdate(id).orElseThrow(() -> new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));
        rooms.requireMember(a.getRoomId(), user);
        if (!a.getHostId().equals(user)) throw new BusinessException(ErrorCode.APPOINTMENT_HOST_ONLY);
        media.validateReference(user, r.coverImageUrl());
        a.decorate(r.coverImageUrl(), r.cardText(), r.cardStyle());
        return appointments.get(user, id);
    }
}
