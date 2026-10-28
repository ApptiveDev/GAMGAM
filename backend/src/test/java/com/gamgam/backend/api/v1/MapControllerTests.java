package com.gamgam.backend.api.v1;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.exception.GlobalExceptionHandler;
import com.gamgam.backend.map.RoomMapService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

class MapControllerTests {
    private RoomMapService service;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        service = mock(RoomMapService.class);
        mvc = MockMvcBuilders.standaloneSetup(new MapController(service))
                .setControllerAdvice(new GlobalExceptionHandler()).build();
    }

    @Test
    void mapUsesAuthenticatedUserId() throws Exception {
        mvc.perform(get("/api/v1/rooms/room-1/map")
                        .requestAttr(AuthInterceptor.USER_ID_ATTRIBUTE, "user-1")
                        .param("latitude", "37.5").param("longitude", "127.0"))
                .andExpect(status().isOk());
        verify(service).getMap("room-1", "user-1", 37.5, 127.0);
    }

    @Test
    void requiresCoordinates() throws Exception {
        mvc.perform(get("/api/v1/rooms/room-1/map")
                        .requestAttr(AuthInterceptor.USER_ID_ATTRIBUTE, "user-1"))
                .andExpect(status().isBadRequest());
    }
}
