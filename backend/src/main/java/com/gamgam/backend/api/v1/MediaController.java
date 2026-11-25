package com.gamgam.backend.api.v1;
import com.gamgam.backend.media.*;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.global.response.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.http.*;
@RestController @RequiredArgsConstructor @RequestMapping("/api/v1/media")
public class MediaController {
    private final MediaService service;
    @PostMapping(consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<MediaService.Uploaded>> upload(@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user,
            @RequestPart("file") MultipartFile file) {return ResponseEntity.status(201).body(ApiResponse.ok(service.upload(user,file)));}
    @GetMapping("/{id}")
    public ResponseEntity<byte[]> get(@PathVariable String id,@RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String user) {
        var asset=service.get(user,id);
        return ResponseEntity.ok().contentType(MediaType.parseMediaType(asset.getContentType())).cacheControl(CacheControl.noStore())
                .header("X-Content-Type-Options","nosniff").body(asset.getContent());
    }
}
