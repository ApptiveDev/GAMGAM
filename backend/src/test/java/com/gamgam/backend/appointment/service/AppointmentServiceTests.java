package com.gamgam.backend.appointment.service;

import static com.gamgam.backend.appointment.AppointmentFixtures.all;
import static com.gamgam.backend.appointment.AppointmentFixtures.both;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.entity.AppointmentMember;
import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentPlaceVoteRepository;
import com.gamgam.backend.appointment.repository.AppointmentParticipantRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.repository.AppointmentTimeVoteRepository;
import com.gamgam.backend.appointment.repository.PenaltyAgreementRepository;
import com.gamgam.backend.appointment.vo.AppointmentMemberRole;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.global.config.ShareProperties;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.user.repository.UserRepository;
import com.gamgam.backend.room.RoomAccess;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class AppointmentServiceTests {
    private AppointmentRepository appointments;
    private AppointmentMemberRepository members;
    private UserRepository users;
    private AppointmentService service;
    private User user;

    @BeforeEach
    void setUp() {
        appointments = mock(AppointmentRepository.class);
        members = mock(AppointmentMemberRepository.class);
        var timeVotes = mock(AppointmentTimeVoteRepository.class);
        var placeVotes = mock(AppointmentPlaceVoteRepository.class);
        var participants = mock(AppointmentParticipantRepository.class);
        var agreements = mock(PenaltyAgreementRepository.class);
        users = mock(UserRepository.class);
        RoomAccess rooms = mock(RoomAccess.class);
        service = new AppointmentService(appointments, members, timeVotes, placeVotes, participants, agreements, users,
                new ShareLinkGenerator(new ShareProperties("http://localhost:3000")), rooms);
        user = User.builder().id("user-1").email("user@example.com").name("User").passwordHash("hash").build();
        when(users.findById("user-1")).thenReturn(Optional.of(user));
        when(appointments.save(any(Appointment.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(members.save(any(AppointmentMember.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(members.findAllByAppointmentIdOrderByJoinedAtAsc(any())).thenReturn(List.of());
        when(timeVotes.findAllByAppointmentId(any())).thenReturn(List.of());
        when(placeVotes.findAllByAppointmentId(any())).thenReturn(List.of());
        when(agreements.findAllByAppointmentId(any())).thenReturn(List.of());
    }

    @Test
    void creatorBecomesHostAndGetsInviteCode() {
        var response = service.create("demo-room", "user-1", all());

        assertThat(response.hostId()).isEqualTo("user-1");
        assertThat(response.inviteCode()).hasSize(8);
        assertThat(response.shareUrl()).endsWith("/invite/" + response.inviteCode());
        assertThat(response.status()).isEqualTo(AppointmentStatus.CONFIRMED);
    }

    @Test
    void coordinatingTemplateStartsCoordinating() {
        assertThat(service.create("demo-room", "user-1", both()).status()).isEqualTo(AppointmentStatus.COORDINATING);
    }

    @Test
    void outsiderCannotReadAppointment() {
        Appointment appointment = Appointment.builder().id("a-1").name("meeting").roomId("demo-room")
                .hostId("host").inviteCode("ABCDEFGH").template(com.gamgam.backend.appointment.vo.AppointmentTemplate.ALL)
                .status(AppointmentStatus.CONFIRMED).build();
        when(appointments.findById("a-1")).thenReturn(Optional.of(appointment));
        when(members.existsByAppointmentIdAndUserId("a-1", "user-1")).thenReturn(false);

        assertThatThrownBy(() -> service.get("user-1", "a-1"))
                .isInstanceOfSatisfying(BusinessException.class,
                        error -> assertThat(error.errorCode()).isEqualTo(ErrorCode.APPOINTMENT_ACCESS_DENIED));
    }

    @Test
    void duplicateJoinIsRejected() {
        Appointment appointment = Appointment.builder().id("a-1").name("meeting").roomId("demo-room")
                .hostId("host").inviteCode("ABCDEFGH").template(com.gamgam.backend.appointment.vo.AppointmentTemplate.ALL)
                .status(AppointmentStatus.CONFIRMED).build();
        when(appointments.findByInviteCode("ABCDEFGH")).thenReturn(Optional.of(appointment));
        when(members.existsByAppointmentIdAndUserId("a-1", "user-1")).thenReturn(true);

        assertThatThrownBy(() -> service.join("user-1", "abcdefgh"))
                .isInstanceOfSatisfying(BusinessException.class,
                        error -> assertThat(error.errorCode()).isEqualTo(ErrorCode.ALREADY_JOINED));
    }
}
