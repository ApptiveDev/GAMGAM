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
class AppointmentRoomApiTests {
    @Autowired WebApplicationContext context;
    @Autowired AppointmentService service;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
    }

    private String validBody() {
        return """
                {"name":"방 안의 약속", "template":"ALL", "confirmedTime":"%s",
                 "confirmedPlace":{"name":"서울숲"}}
                """.formatted(OffsetDateTime.now().plusDays(3));
    }

    @Test
    void 방_안에서_생성하고_방별_목록을_조회한다() throws Exception {
        mvc.perform(post("/api/v1/rooms/demo-room/appointments")
                        .contentType(MediaType.APPLICATION_JSON).content(validBody()))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.data.roomId").value("demo-room"));
        mvc.perform(get("/api/v1/rooms/demo-room/appointments"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].roomId").value("demo-room"));
    }

    @Test
    void 방_없는_생성과_전체_목록_경로는_제공하지_않는다() throws Exception {
        mvc.perform(post("/api/v1/appointments").contentType(MediaType.APPLICATION_JSON).content(validBody()))
                .andExpect(status().isNotFound()).andExpect(jsonPath("$.code").value("NOT_FOUND"));
        mvc.perform(get("/api/v1/appointments"))
                .andExpect(status().isNotFound());
    }

    @Test
    void 비멤버는_생성_목록_상세를_조회할_수_없다() throws Exception {
        var id = service.create("demo-room", "u-yeeun", both()).id();
        mvc.perform(post("/api/v1/rooms/demo-room/appointments").header("X-User-Id", "outsider")
                        .contentType(MediaType.APPLICATION_JSON).content(validBody()))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/rooms/demo-room/appointments").header("X-User-Id", "outsider"))
                .andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/appointments/" + id).header("X-User-Id", "outsider"))
                .andExpect(status().isForbidden());
    }
}
