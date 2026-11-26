package com.gamgam.backend.place;
import com.sun.net.httpserver.HttpServer;
import com.gamgam.backend.appointment.dto.AppointmentResponse;
import com.gamgam.backend.appointment.entity.Appointment;
import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.global.exception.*;
import java.net.InetSocketAddress;
import org.junit.jupiter.api.*;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;
class WeatherServiceTests {
    @Test void mapsCurrentWeatherAndPreservesKoreanOffset() throws Exception {
        var server=HttpServer.create(new InetSocketAddress("127.0.0.1",0),0);
        server.createContext("/v1/forecast",exchange->{
            byte[] bytes="{\"current\":{\"temperature_2m\":28.5,\"weather_code\":3,\"time\":\"2030-01-01T09:00\"}}".getBytes();
            exchange.sendResponseHeaders(200,bytes.length);try(var out=exchange.getResponseBody()){out.write(bytes);}
        });server.start();
        try {
            var appointments=mock(AppointmentService.class);
            var a=Appointment.builder().roomId("room").confirmedPlace(new Place("Cafe",37.5,127.0)).build();
            when(appointments.get("user","appointment")).thenReturn(AppointmentResponse.of(a,"url"));
            var service=new WeatherService(appointments,true,"http://127.0.0.1:"+server.getAddress().getPort());
            var result=service.get("user","appointment");
            assertThat(result.temperatureCelsius()).isEqualTo(28.5);
            assertThat(result.weatherCode()).isEqualTo(3);
            assertThat(result.observedAt()).isEqualTo("2030-01-01T09:00+09:00");
            verify(appointments).get("user","appointment");
        } finally {server.stop(0);}
    }
    @Test void unauthorizedRequestNeverCallsProvider() {
        var appointments=mock(AppointmentService.class);
        when(appointments.get("user","appointment")).thenThrow(new BusinessException(ErrorCode.ROOM_ACCESS_DENIED));
        assertThatThrownBy(()->new WeatherService(appointments,true,"http://127.0.0.1:1").get("user","appointment"))
                .isInstanceOfSatisfying(BusinessException.class,e->assertThat(e.errorCode()).isEqualTo(ErrorCode.ROOM_ACCESS_DENIED));
    }
}
