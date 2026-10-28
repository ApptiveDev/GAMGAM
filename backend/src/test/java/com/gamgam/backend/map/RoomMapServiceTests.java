package com.gamgam.backend.map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.user.repository.UserRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class RoomMapServiceTests {
    private LiveLocationRepository locations;
    private AppointmentRepository appointments;
    private AppointmentMemberRepository members;
    private RoomMapService service;

    @BeforeEach
    void setUp() {
        locations = mock(LiveLocationRepository.class);
        appointments = mock(AppointmentRepository.class);
        members = mock(AppointmentMemberRepository.class);
        service = new RoomMapService(locations, appointments, members, mock(UserRepository.class));
    }

    private Appointment activeAppointment() {
        return Appointment.builder()
                .id("room-1").name("meeting").roomId("demo-room").hostId("user-1").inviteCode("ABCDEFGH")
                .template(AppointmentTemplate.ALL)
                .confirmedTime(OffsetDateTime.now())
                .locationSharing(new LocationSharingPolicy(30, 30))
                .status(AppointmentStatus.CONFIRMED).build();
    }

    @Test
    void memberCanReadActiveRoomMap() {
        when(appointments.findById("room-1")).thenReturn(Optional.of(activeAppointment()));
        when(members.existsByAppointmentIdAndUserId("room-1", "user-1")).thenReturn(true);
        when(locations.findByRoomIdAndSharingEnabledTrue("room-1")).thenReturn(List.of());

        var result = service.getMap("room-1", "user-1", 37.5, 127.0);

        assertThat(result.roomId()).isEqualTo("room-1");
        assertThat(result.currentUserId()).isEqualTo("user-1");
    }

    @Test
    void nonMemberCannotReadRoomMap() {
        when(appointments.findById("room-1")).thenReturn(Optional.of(activeAppointment()));
        when(members.existsByAppointmentIdAndUserId("room-1", "outsider")).thenReturn(false);

        assertThatThrownBy(() -> service.getMap("room-1", "outsider", 0, 0))
                .isInstanceOfSatisfying(BusinessException.class,
                        error -> assertThat(error.errorCode()).isEqualTo(ErrorCode.ROOM_ACCESS_DENIED));
    }

    @Test
    void missingRoomReturnsNotFound() {
        when(appointments.findById("missing")).thenReturn(Optional.empty());
        assertThatThrownBy(() -> service.getMap("missing", "user-1", 0, 0))
                .isInstanceOfSatisfying(BusinessException.class,
                        error -> assertThat(error.errorCode()).isEqualTo(ErrorCode.ROOM_NOT_FOUND));
    }
}
