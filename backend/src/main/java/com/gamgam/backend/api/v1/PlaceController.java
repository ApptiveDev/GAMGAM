package com.gamgam.backend.api.v1;
import com.gamgam.backend.place.*;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import com.gamgam.backend.global.exception.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController @RequiredArgsConstructor @RequestMapping("/api/v1")
public class PlaceController {
    private final PlaceService service;
    private final ExternalPlaceClient external;
    private final WeatherService weather;
    @GetMapping("/places/search")
    public ApiResponse<ExternalPlaceClient.SearchResult> search(@RequestParam String query,@RequestParam(defaultValue="false") boolean address,
            @RequestParam(required=false) Double latitude,@RequestParam(required=false) Double longitude,
            @RequestParam(defaultValue="1") int page,@RequestParam(defaultValue="15") int size) {
        validate(query,latitude,longitude);if(query.isBlank() || page<1 || page>45 || size<1 || size>15) throw new BusinessException(ErrorCode.BAD_REQUEST);
        return ApiResponse.ok(external.search(query,address,latitude,longitude,page,size));
    }
    @GetMapping("/places/saved")
    public ApiResponse<java.util.List<PlaceService.Saved>> saved(@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {return ApiResponse.ok(service.saved(user));}
    @PostMapping("/places/saved")
    public ApiResponse<PlaceService.Saved> save(@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,@Valid @RequestBody PlaceService.SaveRequest r) {return ApiResponse.ok(service.save(user,r));}
    @DeleteMapping("/places/saved/{id}")
    public ApiResponse<Void> delete(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {service.delete(user,id);return ApiResponse.ok(null);}
    @GetMapping({"/places/recommendations","/appointments/{id}/recommendations"})
    public ApiResponse<java.util.List<PlaceService.Recommendation>> recommend(@PathVariable(required=false) String id,
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,@RequestParam(defaultValue="ALL") PlaceService.Context context,
            @RequestParam(defaultValue="") String query,@RequestParam(required=false) Double latitude,@RequestParam(required=false) Double longitude,
            @RequestParam(defaultValue="20") int limit,@RequestParam(defaultValue="false") boolean refresh) {
        validate(query,latitude,longitude);if(limit<1 || limit>100) throw new BusinessException(ErrorCode.BAD_REQUEST);
        return ApiResponse.ok(service.recommend(user,id,context,query,latitude,longitude,limit,refresh));
    }
    @GetMapping("/appointments/{id}/weather")
    public ApiResponse<WeatherService.Weather> weather(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {return ApiResponse.ok(weather.get(user,id));}
    private void validate(String query,Double lat,Double lon) {
        if(query.length()>100 || (lat==null)!=(lon==null) || lat!=null && (!Double.isFinite(lat) || !Double.isFinite(lon) || Math.abs(lat)>90 || Math.abs(lon)>180))
            throw new BusinessException(ErrorCode.BAD_REQUEST);
    }
}
