package com.gamgam.backend.place;

import com.fasterxml.jackson.databind.*;
import com.gamgam.backend.appointment.vo.Place;
import com.gamgam.backend.global.exception.*;
import java.net.*;
import java.net.http.*;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/** Fixed provider hosts, bounded timeouts, and no credentials returned to clients. */
@Component
public class ExternalPlaceClient {
    private final String key;
    private final String baseUrl;
    private final HttpClient http=HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build();
    private final ObjectMapper mapper=new ObjectMapper();
    public ExternalPlaceClient(@Value("${app.places.kakao-key:}") String key,
            @Value("${app.places.base-url:https://dapi.kakao.com}") String baseUrl) {this.key=key;this.baseUrl=baseUrl;}
    public record SearchResult(List<Place> items,int page,boolean hasNext,String attribution) {}
    public SearchResult search(String query,boolean address,Double latitude,Double longitude,int page,int size) {
        if(key.isBlank()) throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);
        String url=baseUrl+"/v2/local/search/"+(address?"address":"keyword")+".json?query="
                +URLEncoder.encode(query,StandardCharsets.UTF_8)+"&page="+page+"&size="+size;
        if(!address && latitude!=null) url+="&y="+latitude+"&x="+longitude+"&sort=distance";
        try {
            var response=http.send(HttpRequest.newBuilder(URI.create(url)).timeout(Duration.ofSeconds(5))
                    .header("Authorization","KakaoAK "+key).GET().build(),HttpResponse.BodyHandlers.ofString());
            if(response.statusCode()!=200) throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);
            var root=mapper.readTree(response.body());
            if(!root.path("documents").isArray() || !root.path("meta").isObject()) throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);
            List<Place> places=new ArrayList<>();
            for(var d:root.path("documents")) {
                String road=address?d.path("road_address").path("address_name").asText():d.path("road_address_name").asText();
                String street=road.isBlank()?d.path("address_name").asText():road;
                places.add(new Place(address?street:d.path("place_name").asText(),Double.valueOf(d.path("y").asText()),
                        Double.valueOf(d.path("x").asText()),street,address?null:d.path("category_name").asText(),null,
                        address?null:d.path("id").asText(),address?null:d.path("place_url").asText()));
            }
            return new SearchResult(places,page,!root.path("meta").path("is_end").asBoolean(true),"Kakao Local");
        } catch(InterruptedException e) { Thread.currentThread().interrupt();throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);
        } catch(java.io.IOException | IllegalArgumentException e) {throw new BusinessException(ErrorCode.PROVIDER_UNAVAILABLE);}
    }
}
