package com.gamgam.backend.api.v1;

import com.gamgam.backend.auth.dto.LoginRequest;
import com.gamgam.backend.auth.dto.LoginResponse;
import com.gamgam.backend.auth.dto.SignupRequest;
import com.gamgam.backend.auth.dto.UserResponse;
import com.gamgam.backend.auth.dto.UpdateProfileRequest;
import com.gamgam.backend.auth.security.AuthInterceptor;
import com.gamgam.backend.auth.service.AuthService;
import com.gamgam.backend.global.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<UserResponse>> signup(@Valid @RequestBody SignupRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(authService.signup(request)));
    }

    @PostMapping("/login")
    public ApiResponse<LoginResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }

    @GetMapping("/me")
    public ApiResponse<UserResponse> me(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId) {
        return ApiResponse.ok(authService.me(userId));
    }

    @PatchMapping("/me")
    public ApiResponse<UserResponse> updateProfile(
            @RequestAttribute(AuthInterceptor.USER_ID_ATTRIBUTE) String userId,
            @Valid @RequestBody UpdateProfileRequest request) {
        return ApiResponse.ok(authService.updateProfile(userId, request));
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout() {
        return ApiResponse.ok(null);
    }
}
