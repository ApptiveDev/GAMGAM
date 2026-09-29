package com.gamgam.backend.api.v1;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamgam.backend.global.exception.GlobalExceptionHandler;
import com.gamgam.backend.map.MockRoomRepository;
import com.gamgam.backend.map.RoomMapService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class MapControllerTests {
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        mvc = MockMvcBuilders.standaloneSetup(new MapController(new RoomMapService(new MockRoomRepository())))
                .setControllerAdvice(new GlobalExceptionHandler()).build();
    }

    @Test
    void showsSelfAndOnlySelectedRoomParticipants() throws Exception {
        mvc.perform(get("/api/v1/rooms/a-hiking/map").param("latitude", "35.1796").param("longitude", "129.0756"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.roomId").value("a-hiking"))
                .andExpect(jsonPath("$.data.participants.length()").value(3))
                .andExpect(jsonPath("$.data.participants[0].id").value("u-yeeun"))
                .andExpect(jsonPath("$.data.participants[0].latitude").value(35.1796))
                .andExpect(jsonPath("$.data.participants[0].longitude").value(129.0756))
                .andExpect(jsonPath("$.data.participants[0].self").value(true))
                .andExpect(jsonPath("$.data.participants[0].mock").value(false))
                .andExpect(jsonPath("$.data.participants[1].mock").value(true));
    }

    @ParameterizedTest
    @CsvSource({"missing,404,ROOM_NOT_FOUND", "a-board,403,ROOM_ACCESS_DENIED"})
    void rejectsUnknownOrUnjoinedRoom(String roomId, int status, String code) throws Exception {
        mvc.perform(get("/api/v1/rooms/{roomId}/map", roomId).param("latitude", "0").param("longitude", "0"))
                .andExpect(status().is(status)).andExpect(jsonPath("$.code").value(code));
    }

    @Test
    void requiresCurrentLocation() throws Exception {
        mvc.perform(get("/api/v1/rooms/a-hongdae/map")).andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.fieldErrors.latitude").exists())
                .andExpect(jsonPath("$.fieldErrors.longitude").exists());
    }

    @ParameterizedTest
    @CsvSource({"latitude,91", "latitude,-91", "longitude,181", "longitude,-181",
            "latitude,NaN", "longitude,Infinity", "latitude,-Infinity", "latitude,abc", "latitude,''"})
    void rejectsInvalidCoordinates(String field, String value) throws Exception {
        mvc.perform(get("/api/v1/rooms/a-hongdae/map")
                        .param("latitude", field.equals("latitude") ? value : "37.5563")
                        .param("longitude", field.equals("longitude") ? value : "126.9236"))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("$.code").value("VALIDATION_ERROR"))
                .andExpect(jsonPath("$.fieldErrors." + field).exists());
    }
}
