package com.gamgam.backend.appointment.service;

import static org.assertj.core.api.Assertions.assertThat;

import com.gamgam.backend.appointment.dto.CreateAppointmentRequest.PlaceRequest;
import com.gamgam.backend.appointment.dto.TimeCandidateRequest;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.entity.AppointmentMember;
import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentRepository;
import com.gamgam.backend.appointment.vo.AppointmentMemberRole;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.user.repository.UserRepository;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
class AppointmentVotingServiceTests {
    @Autowired AppointmentVotingService service;
    @Autowired AppointmentRepository appointments;
    @Autowired AppointmentMemberRepository members;
    @Autowired UserRepository users;

    private String appointmentId;
    private String userId;

    @BeforeEach
    void setUp() {
        userId = UUID.randomUUID().toString();
        User user = users.save(User.builder()
                .id(userId)
                .email(userId + "@example.com")
                .name("voter")
                .passwordHash("hash")
                .build());
        appointmentId = UUID.randomUUID().toString();
        Appointment appointment = appointments.save(Appointment.builder()
                .id(appointmentId)
                .name("vote test")
                .roomId("demo-room")
                .hostId(userId)
                .inviteCode(UUID.randomUUID().toString().substring(0, 8))
                .template(AppointmentTemplate.BOTH)
                .candidatesTime(List.of(OffsetDateTime.now().plusDays(1), OffsetDateTime.now().plusDays(2)))
                .candidatesPlace(List.of(new Place("A", 37.5, 127.0), new Place("B", 37.6, 127.1)))
                .locationSharing(LocationSharingPolicy.defaults())
                .status(AppointmentStatus.COORDINATING)
                .build());
        members.save(new AppointmentMember(UUID.randomUUID().toString(), appointment, user,
                AppointmentMemberRole.HOST));
    }

    @Test
    void multipleVotesCanBeReplacedAndCancelled() {
        var selected = service.votePlace(appointmentId, userId, Set.of(0, 1));
        assertThat(selected.participating()).isTrue();
        assertThat(selected.placeOptions()).allMatch(option -> option.votedByMe());

        var replaced = service.votePlace(appointmentId, userId, Set.of(1));
        assertThat(replaced.placeOptions().get(0).votedByMe()).isFalse();
        assertThat(replaced.placeOptions().get(1).votedByMe()).isTrue();

        assertThat(service.votePlace(appointmentId, userId, Set.of()).participating()).isFalse();
    }

    @Test
    void regardlessParticipationClearsCandidateVotes() {
        service.voteTime(appointmentId, userId, Set.of(0, 1));
        service.votePlace(appointmentId, userId, Set.of(0));

        var response = service.participateRegardless(appointmentId, userId, true);
        assertThat(response.participatingRegardless()).isTrue();
        assertThat(response.timeOptions()).noneMatch(option -> option.votedByMe());
        assertThat(response.placeOptions()).noneMatch(option -> option.votedByMe());
    }

    @Test
    void candidatesAreAddedWithoutCreatingVotes() {
        service.addTimeCandidate(appointmentId, userId,
                new TimeCandidateRequest(OffsetDateTime.now().plusDays(3)));
        var response = service.addPlaceCandidate(appointmentId, userId,
                new PlaceRequest(" C ", 37.7, 127.2));

        assertThat(response.timeOptions()).hasSize(3);
        assertThat(response.placeOptions()).hasSize(3);
        assertThat(response.placeOptions().get(2).place().name()).isEqualTo("C");
        assertThat(response.participating()).isFalse();
    }
}
