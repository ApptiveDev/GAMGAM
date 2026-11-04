package com.gamgam.backend.api.v1;

import static com.gamgam.backend.appointment.AppointmentFixtures.both;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;
import com.gamgam.backend.appointment.repository.AppointmentParticipantRepository;
import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.auth.security.JwtTokenProvider;
import com.gamgam.backend.room.*;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.user.repository.UserRepository;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.transaction.annotation.Transactional;

@SpringBootTest
@Transactional
class AppointmentRoomApiTests {
    @Autowired WebApplicationContext context;
    @Autowired AppointmentService service;
    @Autowired JwtTokenProvider tokens;
    @Autowired UserRepository users;
    @Autowired RoomService rooms;
    @Autowired RoomRepository roomRepository;
    @Autowired RoomMemberRepository roomMembers;
    @Autowired AppointmentMemberRepository members;
    @Autowired AppointmentParticipantRepository participants;
    private MockMvc mvc;
    private String roomId;
    private String id;

    private String bearer(String userId) {
        return "Bearer " + tokens.create(users.findById(userId).orElseThrow()).value();
    }

    @BeforeEach
    void setUp() {
        for (String userId : new String[]{"read-host", "read-member", "read-outsider"}) {
            users.save(User.builder().id(userId).email(userId + "@appointment.test")
                    .name(userId).passwordHash("unused").build());
        }
        roomId = rooms.create("read-host", new CreateRoomRequest("Read test room")).id();
        roomMembers.save(new RoomMember(UUID.randomUUID().toString(),
                roomRepository.findById(roomId).orElseThrow(), users.findById("read-member").orElseThrow()));
        id = service.create(roomId, "read-host", both()).id();
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
    }

    @Test
    void roomMemberCanReadBeforeVotingWithoutBecomingParticipant() throws Exception {
        mvc.perform(get("/api/v1/appointments/" + id).header("Authorization", bearer("read-member")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.id").value(id));
        mvc.perform(get("/api/v1/rooms/" + roomId + "/appointments").header("Authorization", bearer("read-member")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value(id));
        mvc.perform(get("/api/v1/appointments/" + id + "/votes").header("Authorization", bearer("read-member")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.participating").value(false));
        assertThat(members.existsByAppointmentIdAndUserId(id, "read-member")).isFalse();
        assertThat(participants.findByAppointmentIdAndUserId(id, "read-member")).isEmpty();
    }

    @Test
    void allAppointmentsIncludeOnlyJoinedRoomsEvenBeforeVoting() throws Exception {
        String otherRoom = rooms.create("read-outsider", new CreateRoomRequest("Other room")).id();
        var hidden = service.create(otherRoom, "read-outsider", both());
        // Legacy appointment membership must not grant access to a different room.
        service.join("read-member", hidden.inviteCode());
        mvc.perform(get("/api/v1/appointments").header("Authorization", bearer("read-member")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value(id));
        mvc.perform(get("/api/v1/appointments/" + hidden.id()).header("Authorization", bearer("read-member")))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROOM_ACCESS_DENIED"));
    }

    @Test
    void outsiderCannotReadRoomOrAppointment() throws Exception {
        for (String path : new String[]{"/api/v1/appointments/" + id,
                "/api/v1/rooms/" + roomId + "/appointments", "/api/v1/appointments/" + id + "/votes"}) {
            mvc.perform(get(path).header("Authorization", bearer("read-outsider")))
                    .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROOM_ACCESS_DENIED"));
        }
        mvc.perform(get("/api/v1/appointments").header("Authorization", bearer("read-outsider")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data").isEmpty());
    }

    @Test
    void readAccessDoesNotGrantMemberOrHostActions() throws Exception {
        mvc.perform(delete("/api/v1/appointments/" + id + "/members/me")
                        .header("Authorization", bearer("read-member")))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("APPOINTMENT_ACCESS_DENIED"));
        service.join("read-member", service.get("read-host", id).inviteCode());
        mvc.perform(post("/api/v1/appointments/" + id + "/confirm")
                        .header("Authorization", bearer("read-member"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"timeOptionIndex\":0,\"placeOptionIndex\":0}"))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("APPOINTMENT_HOST_ONLY"));
    }

    @Test
    void missingAppointmentReturnsNotFound() throws Exception {
        mvc.perform(get("/api/v1/appointments/missing").header("Authorization", bearer("read-member")))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("APPOINTMENT_NOT_FOUND"));
    }

    @Test
    void readsRequireAuthentication() throws Exception {
        for (String path : new String[]{"/api/v1/appointments", "/api/v1/appointments/" + id,
                "/api/v1/rooms/" + roomId + "/appointments"}) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
        }
    }
}
