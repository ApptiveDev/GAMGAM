package com.gamgam.backend.api.v1;

import static com.gamgam.backend.appointment.AppointmentFixtures.both;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.gamgam.backend.appointment.service.AppointmentService;
import java.time.OffsetDateTime;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest
class AppointmentVotingControllerTests {
    @Autowired WebApplicationContext context;
    @Autowired AppointmentService appointments;
    private MockMvc mvc;
    private String base;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
        base = "/api/v1/appointments/" + appointments.create("demo-room", "u-yeeun", both()).id();
    }

    @Test
    void 시간과_장소_복수_투표는_실제로_저장되고_다른_사용자에게도_보인다() throws Exception {
        for (String type : new String[]{"time", "place"}) {
            mvc.perform(put(base + "/votes/" + type).header("X-User-Id", "u-doyun")
                            .contentType(MediaType.APPLICATION_JSON).content("{\"optionIndexes\":[0,1,1]}"))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.participating").value(true))
                    .andExpect(jsonPath("$.data.participantIds.length()").value(1));
        }
        mvc.perform(get(base + "/votes").header("X-User-Id", "u-yeeun"))
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
        mvc.perform(put(base + "/votes/place").header("X-User-Id", "outsider")
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
