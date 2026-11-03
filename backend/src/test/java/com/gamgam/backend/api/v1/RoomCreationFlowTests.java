package com.gamgam.backend.api.v1;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamgam.backend.auth.dto.LoginRequest;
import com.gamgam.backend.auth.dto.SignupRequest;
import com.gamgam.backend.auth.service.AuthService;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.web.context.WebApplicationContext;

@SpringBootTest
class RoomCreationFlowTests {
    @Autowired WebApplicationContext context;
    @Autowired AuthService auth;
    private final ObjectMapper mapper = new ObjectMapper();
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.webAppContextSetup(context).build();
    }

    @Test
    void authenticatedOwnerCanCreateRoomAndNameOnlyAppointmentButOutsiderCannot() throws Exception {
        String ownerEmail = UUID.randomUUID() + "@example.com";
        String outsiderEmail = UUID.randomUUID() + "@example.com";
        String ownerId = auth.signup(new SignupRequest(ownerEmail, "password123", "Owner User")).id();
        auth.signup(new SignupRequest(outsiderEmail, "password123", "Other User"));
        String ownerToken = auth.login(new LoginRequest(ownerEmail, "password123")).accessToken();
        String outsiderToken = auth.login(new LoginRequest(outsiderEmail, "password123")).accessToken();

        String roomJson = mvc.perform(post("/api/v1/rooms")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"  앱티브  \"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name").value("앱티브"))
                .andExpect(jsonPath("$.data.ownerId").value(ownerId))
                .andExpect(jsonPath("$.data.memberCount").value(1))
                .andReturn().getResponse().getContentAsString();
        JsonNode room = mapper.readTree(roomJson).path("data");
        String roomId = room.path("id").asText();
        assertThat(roomId).isNotBlank();

        mvc.perform(get("/api/v1/rooms").header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(roomId));
        mvc.perform(get("/api/v1/rooms").header("Authorization", "Bearer " + outsiderToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
        mvc.perform(get("/api/v1/rooms/" + roomId).header("Authorization", "Bearer " + outsiderToken))
                .andExpect(status().isForbidden());

        String appointmentJson = mvc.perform(post("/api/v1/rooms/" + roomId + "/appointments")
                        .header("Authorization", "Bearer " + ownerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"토요일 등산\"}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.roomId").value(roomId))
                .andExpect(jsonPath("$.data.hostId").value(ownerId))
                .andExpect(jsonPath("$.data.template").value("BOTH"))
                .andExpect(jsonPath("$.data.status").value("COORDINATING"))
                .andExpect(jsonPath("$.data.candidatesTime.length()").value(0))
                .andExpect(jsonPath("$.data.candidatesPlace.length()").value(0))
                .andReturn().getResponse().getContentAsString();
        String appointmentId = mapper.readTree(appointmentJson).path("data").path("id").asText();

        mvc.perform(get("/api/v1/rooms/" + roomId + "/appointments")
                        .header("Authorization", "Bearer " + ownerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(appointmentId));
        mvc.perform(post("/api/v1/rooms/" + roomId + "/appointments")
                        .header("Authorization", "Bearer " + outsiderToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"name\":\"몰래 만든 약속\"}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.code").value("ROOM_ACCESS_DENIED"));
    }

    @Test
    void roomCreationRequiresAuthenticationAndValidName() throws Exception {
        mvc.perform(post("/api/v1/rooms")
                        .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"앱티브\"}"))
                .andExpect(status().isUnauthorized());

        String email = UUID.randomUUID() + "@example.com";
        auth.signup(new SignupRequest(email, "password123", "Owner User"));
        String token = auth.login(new LoginRequest(email, "password123")).accessToken();
        mvc.perform(post("/api/v1/rooms")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON).content("{\"name\":\"   \"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.code").value("VALIDATION_ERROR"));
    }
}
