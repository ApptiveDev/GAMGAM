package com.gamgam.backend.api.v1;

import static org.mockito.ArgumentMatchers.any;
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
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
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

    private AppointmentService service;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        service = mock(AppointmentService.class);
        mvc = MockMvcBuilders.standaloneSetup(new AppointmentController(service))
                .setControllerAdvice(new GlobalExceptionHandler()).build();
    }

    private static String futureIso(int days) {
        return OffsetDateTime.now().plusDays(days).withNano(0).toString();
    }

    private static AppointmentResponse sampleResponse() {
        return new AppointmentResponse("id-1", "홍대 저녁 모임", AppointmentTemplate.ALL,
                List.of(), OffsetDateTime.parse("2030-01-01T19:00:00+09:00"), List.of(), null,
                null, null, LocationSharingPolicy.defaults(), AppointmentStatus.CONFIRMED,
                "http://localhost:3000/appointments/id-1", Instant.parse("2030-01-01T00:00:00Z"));
    }

    private static String validAllBody() {
        return """
                {
                  "name": "홍대 저녁 모임",
                  "template": "ALL",
                  "confirmedTime": "%s",
                  "confirmedPlace": {"name": "연남동", "latitude": 37.55, "longitude": 126.92}
                }
                """.formatted(futureIso(3));
    }

    @Test
    void 약속을_만들면_201과_응답을_돌려준다() throws Exception {
        when(service.create(any(CreateAppointmentRequest.class))).thenReturn(sampleResponse());

        mvc.perform(post("/api/v1/appointments").contentType(MediaType.APPLICATION_JSON).content(validAllBody()))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value("id-1"))
                .andExpect(jsonPath("$.data.status").value("CONFIRMED"))
                .andExpect(jsonPath("$.data.shareUrl").value("http://localhost:3000/appointments/id-1"));
    }

    @Test
    void 이름이_없으면_400과_필드에러를_돌려준다() throws Exception {
        var body = """
                {"template": "ALL", "confirmedTime": "%s",
                 "confirmedPlace": {"name": "연남동"}}
                """.formatted(futureIso(3));

        mvc.perform(post("/api/v1/appointments").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors.name").exists());

        verify(service, never()).create(any());
    }

    @Test
    void 템플릿과_맞지_않는_요청은_400이다() throws Exception {
        // TIME_ONLY인데 시간 후보가 없다
        var body = """
                {"name": "모임", "template": "TIME_ONLY",
                 "confirmedPlace": {"name": "연남동"}}
                """;

        mvc.perform(post("/api/v1/appointments").contentType(MediaType.APPLICATION_JSON).content(body))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors.candidatesTimeConsistent").exists());
    }

    @Test
    void 약속을_조회한다() throws Exception {
        when(service.get("id-1")).thenReturn(sampleResponse());

        mvc.perform(get("/api/v1/appointments/{id}", "id-1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.name").value("홍대 저녁 모임"));
    }

    @Test
    void 없는_약속은_404다() throws Exception {
        when(service.get("missing")).thenThrow(new BusinessException(ErrorCode.APPOINTMENT_NOT_FOUND));

        mvc.perform(get("/api/v1/appointments/{id}", "missing"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.code").value("APPOINTMENT_NOT_FOUND"));
    }
}
