package com.gamgam.backend.api.v1;

import static com.gamgam.backend.appointment.AppointmentFixtures.both;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.auth.security.JwtTokenProvider;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.user.repository.UserRepository;
import com.gamgam.backend.room.CreateRoomRequest;
import com.gamgam.backend.room.RoomMember;
import com.gamgam.backend.room.RoomMemberRepository;
import com.gamgam.backend.room.RoomRepository;
import com.gamgam.backend.room.RoomService;
import java.util.UUID;
import java.time.OffsetDateTime;
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
class AppointmentVotingControllerTests {
    @Autowired WebApplicationContext context;
    @Autowired AppointmentService appointments;
    @Autowired JwtTokenProvider tokens;
    @Autowired UserRepository users;
    @Autowired RoomService rooms;
    @Autowired RoomRepository roomRepository;
    @Autowired RoomMemberRepository roomMembers;
    private String roomId;

    private String bearer(String userId) {
        return "Bearer " + tokens.create(users.findById(userId).orElseThrow()).value();
    }

    private void setUpUsersAndRoom() {
        for (String userId : new String[]{"u-yeeun", "u-doyun", "outsider"}) {
            users.save(User.builder().id(userId).email(userId + "@voting.test")
                    .name(userId).passwordHash("unused").build());
        }
        roomId = rooms.create("u-yeeun", new CreateRoomRequest("Voting test room")).id();
        roomMembers.save(new RoomMember(UUID.randomUUID().toString(),
                roomRepository.findById(roomId).orElseThrow(), users.findById("u-doyun").orElseThrow()));
    }

    private MockMvc mvc;
    private String base;

    @BeforeEach
    void setUp() {
        setUpUsersAndRoom();
        mvc = MockMvcBuilders.webAppContextSetup(context)
                .defaultRequest(get("/").header("Authorization", bearer("u-yeeun"))).build();
        base = "/api/v1/appointments/" + appointments.create(roomId, "u-yeeun", both()).id();
    }

    @Test
    void authenticatedUsersKeepIndependentVotesDespiteSpoofedHeader() throws Exception {
        for (String type : new String[]{"time", "place"}) {
            mvc.perform(put(base + "/votes/" + type)
                            .header("Authorization", bearer("u-doyun"))
                            .header("X-User-Id", "u-yeeun")
                            .contentType(MediaType.APPLICATION_JSON).content("{\"optionIndexes\":[0]}"))
                    .andExpect(status().isOk());
            mvc.perform(put(base + "/votes/" + type)
                            .header("Authorization", bearer("u-yeeun"))
                            .contentType(MediaType.APPLICATION_JSON).content("{\"optionIndexes\":[1]}"))
                    .andExpect(status().isOk());
        }
        for (String userId : new String[]{"u-doyun", "u-yeeun"}) {
            mvc.perform(get(base + "/votes").header("Authorization", bearer(userId)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.timeOptions[0].voterIds[0]").value("u-doyun"))
                    .andExpect(jsonPath("$.data.timeOptions[1].voterIds[0]").value("u-yeeun"))
                    .andExpect(jsonPath("$.data.placeOptions[0].voterIds[0]").value("u-doyun"))
                    .andExpect(jsonPath("$.data.placeOptions[1].voterIds[0]").value("u-yeeun"))
                    .andExpect(jsonPath("$.data.timeOptions[0].votedByMe").value(userId.equals("u-doyun")))
                    .andExpect(jsonPath("$.data.placeOptions[1].votedByMe").value(userId.equals("u-yeeun")));
        }
    }

    @Test
    void allVotingEndpointsRejectMissingOrInvalidAuthentication() throws Exception {
        MockMvc unauthenticatedMvc = MockMvcBuilders.webAppContextSetup(context).build();
        for (String authorization : new String[]{"", "Bearer invalid-token"}) {
            var requests = java.util.List.of(
                    get(base + "/votes"),
                    put(base + "/votes/time").content("{\"optionIndexes\":[0]}"),
                    put(base + "/votes/place").content("{\"optionIndexes\":[0]}"),
                    put(base + "/votes/regardless").content("{\"selected\":true}"),
                    post(base + "/time-candidates").content("{\"time\":\"2035-01-01T10:00:00Z\"}"),
                    post(base + "/place-candidates").content("{\"name\":\"Cafe\"}"));
            for (var request : requests) {
                unauthenticatedMvc.perform(request.header("Authorization", authorization)
                                .header("X-User-Id", "u-yeeun").contentType(MediaType.APPLICATION_JSON))
                        .andExpect(status().isUnauthorized());
            }
        }
    }

    @Test
    void 시간과_장소_복수_투표는_실제로_저장되고_다른_사용자에게도_보인다() throws Exception {
        for (String type : new String[]{"time", "place"}) {
            mvc.perform(put(base + "/votes/" + type).header("Authorization", bearer("u-doyun"))
                            .contentType(MediaType.APPLICATION_JSON).content("{\"optionIndexes\":[0,1,1]}"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.participating").value(true))
                    .andExpect(jsonPath("$.data.participantIds.length()").value(1));
        }
        mvc.perform(get(base + "/votes").header("Authorization", bearer("u-yeeun")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.participating").value(false))
                .andExpect(jsonPath("$.data.timeOptions[0].voteCount").value(1))
                .andExpect(jsonPath("$.data.placeOptions[1].voterIds[0]").value("u-doyun"))
                .andExpect(jsonPath("$.data.placeOptions[1].votedByMe").value(false));
    }

    @Test
    void 상관없이_참여와_취소가_후보_투표없이_가능하다() throws Exception {
        mvc.perform(put(base + "/votes/regardless").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"selected\":true}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.participatingRegardless").value(true))
                .andExpect(jsonPath("$.data.regardlessParticipantIds[0]").value("u-yeeun"));
        mvc.perform(put(base + "/votes/regardless").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"selected\":false}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.participating").value(false));
    }

    @Test
    void 후보_장소를_추가하고_추가된_인덱스로_투표한다() throws Exception {
        mvc.perform(post(base + "/place-candidates").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"새 카페\",\"latitude\":37.5,\"longitude\":127.0}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.placeOptions[2].place.name").value("새 카페"))
                .andExpect(jsonPath("$.data.placeOptions[2].voteCount").value(0))
                .andExpect(jsonPath("$.data.participating").value(false));
        mvc.perform(put(base + "/votes/place").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"optionIndexes\":[2]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.placeOptions[2].votedByMe").value(true));
    }

    @Test
    void 누락_null_음수_투표는_400이다() throws Exception {
        for (String type : new String[]{"time", "place"}) {
            for (String body : new String[]{"{}", "{\"optionIndexes\":null}",
                    "{\"optionIndexes\":[null]}", "{\"optionIndexes\":[-1]}"}) {
                mvc.perform(put(base + "/votes/" + type).contentType(MediaType.APPLICATION_JSON).content(body))
                        .andExpect(status().isBadRequest())
                        .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
            }
        }
        mvc.perform(put(base + "/votes/regardless").contentType(MediaType.APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void 잘못된_후보_장소는_400이다() throws Exception {
        for (String body : new String[]{"{\"name\":\"  \"}", "{\"name\":\"카페\",\"latitude\":37.5}",
                "{\"name\":\"카페\",\"latitude\":91,\"longitude\":127}"}) {
            mvc.perform(post(base + "/place-candidates").contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        }
    }

    @Test
    void 외부인과_없는_약속은_각각_403과_404다() throws Exception {
        mvc.perform(put(base + "/votes/place").header("Authorization", bearer("outsider"))
                        .contentType(MediaType.APPLICATION_JSON).content("{\"optionIndexes\":[0]}"))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROOM_ACCESS_DENIED"));
        mvc.perform(get("/api/v1/appointments/missing/votes"))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("APPOINTMENT_NOT_FOUND"));
    }

    @Test
    void 방에_연결된_약속을_생성한다() throws Exception {
        String time = OffsetDateTime.now().plusDays(3).toString();
        String body = """
                {"name":"새 약속", "template":"PLACE_ONLY", "confirmedTime":"%s",
                 "candidatesPlace":[{"name":"카페 A"},{"name":"카페 B"}]}
                """.formatted(time);
        mvc.perform(post("/api/v1/rooms/demo-room/appointments").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.data.status").value("COORDINATING"));
        mvc.perform(post("/api/v1/rooms/missing/appointments").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isNotFound());
    }
    @Test
    void 시간_후보를_추가하고_새_인덱스에_투표한다() throws Exception {
        String time = OffsetDateTime.now().plusDays(5).withNano(123456789).toString();
        mvc.perform(post(base + "/time-candidates").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"time\":\"" + time + "\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.timeOptions[2].index").value(2))
                .andExpect(jsonPath("$.data.timeOptions[2].voteCount").value(0))
                .andExpect(jsonPath("$.data.timeOptions[2].time", org.hamcrest.Matchers.endsWith("+09:00")))
                .andExpect(jsonPath("$.data.participating").value(false));
        mvc.perform(put(base + "/votes/time").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"optionIndexes\":[2]}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.timeOptions[2].votedByMe").value(true));
        mvc.perform(post(base + "/time-candidates").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"time\":\"" + time + "\"}"))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.code").value("DUPLICATE_CANDIDATE"));
    }

    @Test
    void 잘못된_시간_후보_입력은_거부한다() throws Exception {
        for (String body : new String[]{"{}", "{\"time\":null}", "{\"time\":\"2000-01-01T00:00:00Z\"}"}) {
            mvc.perform(post(base + "/time-candidates").contentType(MediaType.APPLICATION_JSON).content(body))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        }
        mvc.perform(post(base + "/time-candidates").contentType(MediaType.APPLICATION_JSON)
                        .content("{\"time\":\"not-a-date\"}"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("BAD_REQUEST"));
    }


}
