package com.gamgam.backend.api.v1;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.dto.CreateAppointmentRequest;
import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.appointment.vo.AppointmentStatus;
import com.gamgam.backend.appointment.vo.AppointmentTemplate;
import com.gamgam.backend.appointment.vo.LocationSharingPolicy;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.exception.GlobalExceptionHandler;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.util.List;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class AppointmentControllerTests {
    private static final String USER_ID = "user-1";
    private AppointmentService service;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        service = mock(AppointmentService.class);
        mvc = MockMvcBuilders.standaloneSetup(new AppointmentController(service))
                .setControllerAdvice(new GlobalExceptionHandler()).build();
    }

    private static AppointmentResponse sample() {
        return new AppointmentResponse("id-1", "meeting", AppointmentTemplate.ALL,
                List.of(), OffsetDateTime.parse("2030-01-01T19:00:00+09:00"), List.of(), null,
                null, null, LocationSharingPolicy.defaults(), AppointmentStatus.CONFIRMED,
                "http://localhost:3000/invite/ABCDEFGH", Instant.parse("2030-01-01T00:00:00Z"));
    }

    @Test
    void authenticatedUserCreatesAppointment() throws Exception {
        when(service.create(eq("demo-room"), eq(USER_ID), any(CreateAppointmentRequest.class))).thenReturn(sample());
        String body = """
                {"name":"meeting","template":"ALL","confirmedTime":"2030-01-01T19:00:00+09:00",
                 "confirmedPlace":{"name":"Seoul"}}
                """;
        mvc.perform(post("/api/v1/rooms/demo-room/appointments")
                        .requestAttr(AuthInterceptor.USER_ID_ATTRIBUTE, USER_ID)
                        .contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value("id-1"));
    }

    @Test
    void invalidCreateRequestDoesNotCallService() throws Exception {
        mvc.perform(post("/api/v1/rooms/demo-room/appointments")
                        .requestAttr(AuthInterceptor.USER_ID_ATTRIBUTE, USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"\",\"template\":\"ALL\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
        verify(service, never()).create(any(), any(), any());
    }

    @Test
    void listsOnlyAuthenticatedUsersAppointments() throws Exception {
        when(service.list(USER_ID)).thenReturn(List.of(sample()));
        mvc.perform(get("/api/v1/appointments")
                        .requestAttr(AuthInterceptor.USER_ID_ATTRIBUTE, USER_ID))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value("id-1"));
    }

    @Test
    void joinsWithInviteCode() throws Exception {
        when(service.join(USER_ID, "ABCDEFGH")).thenReturn(sample());
        mvc.perform(post("/api/v1/appointments/join")
                        .requestAttr(AuthInterceptor.USER_ID_ATTRIBUTE, USER_ID)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"inviteCode\":\"ABCDEFGH\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value("id-1"));
    }
}
