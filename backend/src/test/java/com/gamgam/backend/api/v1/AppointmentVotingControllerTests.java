package com.gamgam.backend.api.v1;

import static com.gamgam.backend.appointment.AppointmentFixtures.both;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import com.gamgam.backend.appointment.service.AppointmentService;
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
    void 외부인과_없는_약속은_각각_403과_404다() throws Exception {
        mvc.perform(put(base + "/votes/place").header("X-User-Id", "outsider")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"optionIndexes\":[0]}"))
                .andExpect(status().isForbidden()).andExpect(jsonPath("$.code").value("ROOM_ACCESS_DENIED"));
        mvc.perform(get("/api/v1/appointments/missing/votes"))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("APPOINTMENT_NOT_FOUND"));
    }

}
