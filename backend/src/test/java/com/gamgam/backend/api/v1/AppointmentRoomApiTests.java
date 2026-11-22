package com.gamgam.backend.api.v1;

import static com.gamgam.backend.appointment.AppointmentFixtures.both;
import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.gamgam.backend.appointment.repository.AppointmentMemberRepository;

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

    private String candidateId(String type, int position) {
        var appointment = service.get("read-host", id);
        return type.equals("time") ? appointment.candidatesTime().get(position).candidateId()
                : appointment.candidatesPlace().get(position).candidateId();
    }

    private String voteBody(String type, int... positions) {
        return "{\"candidateIds\":[" + java.util.Arrays.stream(positions)
                .mapToObj(position -> "\"" + candidateId(type, position) + "\"")
                .collect(java.util.stream.Collectors.joining(",")) + "]}";
    }
    private String confirmBody(String type, int position) {
        return "{\"candidateId\":\"" + candidateId(type, position) + "\"}";
    }
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
        mvc.perform(post("/api/v1/appointments/" + id + "/confirm/time")
                        .header("Authorization", bearer("read-member"))
                        .contentType(MediaType.APPLICATION_JSON).content(confirmBody("time", 0)))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("APPOINTMENT_HOST_ONLY"));
    }

    @Test
    void individualConfirmationRequiresBodyAndValidCandidateId() throws Exception {
        for (String type : new String[]{"time", "place"}) {
            String path = "/api/v1/appointments/" + id + "/confirm/" + type;
            mvc.perform(post(path).header("Authorization", bearer("read-host")))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("BAD_REQUEST"));
            for (String body : new String[]{"{}", "{\"candidateId\":null}", "{\"candidateId\":\" \"}"}) {
                mvc.perform(post(path).header("Authorization", bearer("read-host"))
                                .contentType(MediaType.APPLICATION_JSON).content(body))
                        .andExpect(status().isBadRequest())
                        .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
            }
            mvc.perform(post(path).header("Authorization", bearer("read-host"))
                            .contentType(MediaType.APPLICATION_JSON).content(confirmBody(type, 1)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.status").value(
                            type.equals("time") ? "COORDINATING" : "CONFIRMED"));
        }
        var result = service.get("read-host", id);
        assertThat(result.confirmedTime()).isEqualTo(result.candidatesTime().get(1).time());
        assertThat(result.confirmedPlace()).isEqualTo(result.candidatesPlace().get(1).place());
    }

    @Test
    void bulkConfirmationEndpointIsRemoved() throws Exception {
        mvc.perform(post("/api/v1/appointments/" + id + "/confirm")
                        .header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"timeOptionIndex\":0,\"placeOptionIndex\":0}"))
                .andExpect(status().isNotFound());
    }

    @Test
    void candidateIdsAreSharedAcrossReadApisAndLegacyIndexRequestsAreRejected() throws Exception {
        String base = "/api/v1/appointments/" + id;
        String token = bearer("read-host");
        for (String type : new String[]{"time", "place"}) {
            String candidateId = candidateId(type, 0);
            String candidates = type.equals("time") ? "candidatesTime" : "candidatesPlace";
            mvc.perform(get(base).header("Authorization", token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data." + candidates + "[0].candidateId").value(candidateId));
            mvc.perform(get(base + "/votes").header("Authorization", token))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data." + type + "Options[0].candidateId").value(candidateId))
                    .andExpect(jsonPath("$.data." + type + "Options[0].index").doesNotHaveJsonPath());
            mvc.perform(put(base + "/votes/" + type).header("Authorization", token)
                            .contentType(MediaType.APPLICATION_JSON).content("{\"optionIndexes\":[0]}"))
                    .andExpect(status().isBadRequest());
            mvc.perform(post(base + "/confirm/" + type).header("Authorization", token)
                            .contentType(MediaType.APPLICATION_JSON).content("{\"optionIndex\":0}"))
                    .andExpect(status().isBadRequest());
            String opposite = candidateId(type.equals("time") ? "place" : "time", 0);
            mvc.perform(put(base + "/votes/" + type).header("Authorization", token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"candidateIds\":[\"" + opposite + "\"]}"))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("INVALID_OPTION"));
            mvc.perform(post(base + "/confirm/" + type).header("Authorization", token)
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"candidateId\":\"" + opposite + "\"}"))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("INVALID_VOTE_OPTION"));
        }
    }

    @Test
    void missingAppointmentReturnsNotFound() throws Exception {
        mvc.perform(get("/api/v1/appointments/missing").header("Authorization", bearer("read-member")))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("APPOINTMENT_NOT_FOUND"));
    }

    @Test
    void votingApiAndAppointmentResponsesShareVotesAndParticipation() throws Exception {
        String base = "/api/v1/appointments/" + id;
        String token = bearer("read-member");
        mvc.perform(put(base + "/votes/time").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content(voteBody("time", 0)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.timeOptions[0].voterIds[0]").value("read-member"));
        mvc.perform(get(base + "/votes").header("Authorization", token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.timeOptions[0].voteCount").value(1))
                .andExpect(jsonPath("$.data.participating").value(true));
        mvc.perform(put(base + "/votes/place").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content(voteBody("place", 1)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.placeOptions[1].voterIds[0]").value("read-member"));
        mvc.perform(put(base + "/votes/time").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content(voteBody("time")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.timeOptions[0].voteCount").value(0));
        mvc.perform(put(base + "/votes/place").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content(voteBody("place")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.participating").value(false));
        mvc.perform(get(base).header("Authorization", token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.placeVotes").isEmpty());
        assertThat(members.existsByAppointmentIdAndUserId(id, "read-member")).isFalse();
        mvc.perform(put(base + "/votes/time").header("Authorization", token)
                        .contentType(MediaType.APPLICATION_JSON).content(voteBody("time", 1)))
                .andExpect(status().isOk());
        mvc.perform(get("/api/v1/rooms/" + roomId + "/appointments").header("Authorization", token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].timeVotes['" + candidateId("time", 1) + "'][0]").value("read-member"));
        mvc.perform(get("/api/v1/appointments").header("Authorization", token))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].timeVotes['" + candidateId("time", 1) + "'][0]").value("read-member"));
    }
    @Test
    void hostCanRenameAndReadUpdatedName() throws Exception {
        var before = service.get("read-host", id);
        mvc.perform(patch("/api/v1/appointments/" + id).header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"  Updated meeting  \"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.name").value("Updated meeting"));
        mvc.perform(get("/api/v1/appointments/" + id).header("Authorization", bearer("read-member")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.name").value("Updated meeting"));
        mvc.perform(get("/api/v1/rooms/" + roomId + "/appointments").header("Authorization", bearer("read-member")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].name").value("Updated meeting"));
        var after = service.get("read-host", id);
        assertThat(after.status()).isEqualTo(before.status());
        assertThat(after.hostId()).isEqualTo(before.hostId());
        assertThat(after.candidatesTime()).isEqualTo(before.candidatesTime());
        assertThat(after.members()).isEqualTo(before.members());
    }

    @Test
    void renameValidatesNameAndAcceptsFiftyCharacters() throws Exception {
        String original = service.get("read-host", id).name();
        for (String body : new String[]{"{}", "{\"name\":null}", "{\"name\":\"   \"}",
                "{\"name\":\"" + "a".repeat(51) + "\"}"}) {
            mvc.perform(patch("/api/v1/appointments/" + id).header("Authorization", bearer("read-host"))
                            .contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isBadRequest());
        }
        assertThat(service.get("read-host", id).name()).isEqualTo(original);
        mvc.perform(patch("/api/v1/appointments/" + id).header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"  " + "a".repeat(50) + "  \"}"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.name").value("a".repeat(50)));
    }

    @Test
    void renameRequiresHostAndAuthentication() throws Exception {
        String original = service.get("read-host", id).name();
        service.join("read-member", service.get("read-host", id).inviteCode());
        for (String userId : new String[]{"read-member", "read-outsider"}) {
            mvc.perform(patch("/api/v1/appointments/" + id).header("Authorization", bearer(userId))
                            .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"Forbidden\"}"))
                    .andExpect(status().isForbidden());
        }
        mvc.perform(patch("/api/v1/appointments/" + id)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"Forbidden\"}"))
                .andExpect(status().isUnauthorized());
        mvc.perform(patch("/api/v1/appointments/missing").header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"Missing\"}"))
                .andExpect(status().isNotFound());
        assertThat(service.get("read-host", id).name()).isEqualTo(original);
    }
    @Test
    void readsRequireAuthentication() throws Exception {
        for (String path : new String[]{"/api/v1/appointments", "/api/v1/appointments/" + id,
                "/api/v1/rooms/" + roomId + "/appointments"}) {
            mvc.perform(get(path)).andExpect(status().isUnauthorized());
        }
    }

    @Test
    void penaltyTargetDefaultsToAllLateOnCreateAndUpdate() throws Exception {
        for (String targetField : new String[]{"", ",\"target\":null",
                ",\"target\":\"ALL_LATE\""}) {
            String penalty = "{\"description\":\"Coffee\",\"lateThresholdMin\":\"TEN\"" + targetField + "}";
            String expected = "ALL_LATE";
            mvc.perform(post("/api/v1/rooms/" + roomId + "/appointments")
                            .header("Authorization", bearer("read-host"))
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"name\":\"Penalty test\",\"penalty\":" + penalty + "}"))
                    .andExpect(status().isCreated())
                    .andExpect(jsonPath("$.data.penalty.target").value(expected))
                    .andExpect(jsonPath("$.data.penaltyAgreedUserIds").doesNotHaveJsonPath());
            mvc.perform(put("/api/v1/appointments/" + id + "/penalty")
                            .header("Authorization", bearer("read-host"))
                            .contentType(MediaType.APPLICATION_JSON).content(penalty))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.penalty.target").value(expected))
                    .andExpect(jsonPath("$.data.penaltyAgreedUserIds").doesNotHaveJsonPath());
            mvc.perform(get("/api/v1/appointments/" + id)
                            .header("Authorization", bearer("read-host")))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.penalty.target").value(expected))
                    .andExpect(jsonPath("$.data.penaltyAgreedUserIds").doesNotHaveJsonPath());
        }
    }

    @Test
    void unsupportedPenaltyTargetIsRejectedOnCreateAndUpdate() throws Exception {
        String penalty = "{\"description\":\"Coffee\",\"lateThresholdMin\":\"TEN\",\"target\":\"LATEST_ONLY\"}";
        mvc.perform(post("/api/v1/rooms/" + roomId + "/appointments")
                        .header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"Penalty test\",\"penalty\":" + penalty + "}"))
                .andExpect(status().isBadRequest());
        mvc.perform(put("/api/v1/appointments/" + id + "/penalty")
                        .header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON).content(penalty))
                .andExpect(status().isBadRequest());
        assertThat(service.get("read-host", id).penalty()).isNull();
    }

    @Test
    void penaltyCanBeEditedUntilBothTimeAndPlaceAreConfirmed() throws Exception {
        String path = "/api/v1/appointments/" + id + "/penalty";
        String initial = "{\"description\":\"Coffee\",\"lateThresholdMin\":\"TEN\"}";
        mvc.perform(put(path).header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON).content(initial))
                .andExpect(status().isOk());
        service.join("read-member", service.get("read-host", id).inviteCode());
        mvc.perform(put(path).header("Authorization", bearer("read-member"))
                        .contentType(MediaType.APPLICATION_JSON).content(initial))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("APPOINTMENT_HOST_ONLY"));

        service.confirmOption("read-host", id, com.gamgam.backend.appointment.vo.VoteType.TIME, candidateId("time", 0));
        String updated = "{\"description\":\"Lunch\",\"lateThresholdMin\":\"FIFTEEN\"}";
        mvc.perform(put(path).header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON).content(updated))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.penalty.description").value("Lunch"));
        service.confirmOption("read-host", id, com.gamgam.backend.appointment.vo.VoteType.PLACE, candidateId("place", 0));
        for (int phase = 0; phase < 2; phase++) {
            if (phase == 1) service.complete("read-host", id);
            mvc.perform(put(path).header("Authorization", bearer("read-host"))
                            .contentType(MediaType.APPLICATION_JSON).content(initial))
                    .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("BAD_REQUEST"));
            assertThat(service.get("read-host", id).penalty().description()).isEqualTo("Lunch");
        }
    }

    @Test
    void penaltyAgreementEndpointIsRemoved() throws Exception {
        service.setPenalty("read-host", id, com.gamgam.backend.appointment.AppointmentFixtures.penalty());
        mvc.perform(post("/api/v1/appointments/" + id + "/penalty/agreement")
                        .header("Authorization", bearer("read-host")))
                .andExpect(status().isNotFound());
    }

    @Test
    void creatingWithoutPenaltyKeepsPenaltyAbsent() throws Exception {
        mvc.perform(post("/api/v1/rooms/" + roomId + "/appointments")
                        .header("Authorization", bearer("read-host"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"No penalty\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.penalty").doesNotExist());
    }
}
