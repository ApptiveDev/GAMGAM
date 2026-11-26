package com.gamgam.backend.place;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gamgam.backend.appointment.service.AppointmentService;
import com.gamgam.backend.global.exception.*;
import java.net.URI;
import java.net.http.*;
import java.time.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class WeatherService {
    private final AppointmentService appointments;
    private final boolean enabled;
    private final String baseUrl;
    private final HttpClient http=HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build();
    public WeatherService(AppointmentService appointments,@Value("${app.weather.enabled:false}") boolean enabled,
            @Value("${app.weather.base-url:https://api.open-meteo.com}") String baseUrl) {this.appointments=appointments;this.enabled=enabled;this.baseUrl=baseUrl;}
    public record Weather(double temperatureCelsius,int weatherCode,String observedAt,String attribution) {}
    public Weather get(String user,String id) {
        var a=appointments.get(user,id);var p=a.confirmedPlace();
        if(p==null || p.latitude()==null) throw new BusinessException(ErrorCode.BAD_REQUEST);
        if(!enabled) throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);
        try {
            var uri=URI.create(baseUrl+"/v1/forecast?latitude="+p.latitude()+"&longitude="+p.longitude()+"&current=temperature_2m,weather_code&timezone=Asia%2FSeoul");
            var r=http.send(HttpRequest.newBuilder(uri).timeout(Duration.ofSeconds(5)).GET().build(),HttpResponse.BodyHandlers.ofString());
            if(r.statusCode()!=200) throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);
            var c=new ObjectMapper().readTree(r.body()).path("current");
            if(!c.path("temperature_2m").isNumber() || !c.path("weather_code").isNumber()) throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);
            return new Weather(c.path("temperature_2m").asDouble(),c.path("weather_code").asInt(),c.path("time").asText()+"+09:00","Open-Meteo");
        } catch(InterruptedException e) {Thread.currentThread().interrupt();throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);
        } catch(java.io.IOException | IllegalArgumentException e) {throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);}
    }
}
