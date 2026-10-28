package com.gamgam.backend.auth.service;

import com.gamgam.backend.auth.dto.LoginRequest;
import com.gamgam.backend.auth.dto.LoginResponse;
import com.gamgam.backend.auth.dto.SignupRequest;
import com.gamgam.backend.auth.dto.UserResponse;
import com.gamgam.backend.auth.dto.UpdateProfileRequest;
import com.gamgam.backend.auth.security.JwtTokenProvider;
import com.gamgam.backend.auth.security.PasswordHasher;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.user.entity.User;
import com.gamgam.backend.user.repository.UserRepository;
import java.util.Locale;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordHasher passwordHasher;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional
    public UserResponse signup(SignupRequest request) {
        String email = normalizeEmail(request.email());
        if (userRepository.existsByEmail(email)) {
            throw new BusinessException(ErrorCode.EMAIL_ALREADY_EXISTS);
        }

        User user = User.builder()
                .id(UUID.randomUUID().toString())
                .email(email)
                .name(request.name().trim())
                .passwordHash(passwordHasher.hash(request.password()))
                .build();
        try {
            return UserResponse.from(userRepository.saveAndFlush(user));
        } catch (DataIntegrityViolationException exception) {
            throw new BusinessException(ErrorCode.EMAIL_ALREADY_EXISTS);
        }
    }

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByEmail(normalizeEmail(request.email()))
                .orElseThrow(() -> new BusinessException(ErrorCode.INVALID_CREDENTIALS));
        if (!passwordHasher.matches(request.password(), user.getPasswordHash())) {
            throw new BusinessException(ErrorCode.INVALID_CREDENTIALS);
        }

        JwtTokenProvider.AccessToken token = jwtTokenProvider.create(user);
        return LoginResponse.bearer(token.value(), token.expiresInSeconds(), UserResponse.from(user));
    }

    public UserResponse me(String userId) {
        return UserResponse.from(findUser(userId));
    }

    @Transactional
    public UserResponse updateProfile(String userId, UpdateProfileRequest request) {
        User user = findUser(userId);
        user.updateName(request.name().trim());
        return UserResponse.from(user);
    }

    private User findUser(String userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new BusinessException(ErrorCode.USER_NOT_FOUND));
    }

    private static String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }
}
