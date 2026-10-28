package com.gamgam.backend.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.gamgam.backend.auth.dto.LoginRequest;
import com.gamgam.backend.auth.dto.SignupRequest;
import com.gamgam.backend.auth.service.AuthService;
import com.gamgam.backend.global.exception.BusinessException;
import com.gamgam.backend.global.exception.ErrorCode;
import com.gamgam.backend.user.repository.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;

@SpringBootTest
class AuthPersistenceTests {

    @Autowired
    private AuthService authService;

    @Autowired
    private UserRepository userRepository;

    @Test
    void signupStoresNormalizedEmailAndHashedPassword() {
        var created = authService.signup(new SignupRequest(
                "  New.User@Example.COM  ", "password123", "New User"));

        var saved = userRepository.findById(created.id()).orElseThrow();
        assertThat(created.email()).isEqualTo("new.user@example.com");
        assertThat(created.createdAt()).isNotNull();
        assertThat(saved.getPasswordHash()).startsWith("pbkdf2_sha256$");
        assertThat(saved.getPasswordHash()).doesNotContain("password123");
    }

    @Test
    void loginReturnsSignedJwtForValidCredentials() {
        authService.signup(new SignupRequest("login@example.com", "password123", "Login User"));

        var response = authService.login(new LoginRequest("LOGIN@example.com", "password123"));

        assertThat(response.tokenType()).isEqualTo("Bearer");
        assertThat(response.expiresIn()).isEqualTo(3600);
        assertThat(response.accessToken().split("\\.")).hasSize(3);
        assertThat(response.user().email()).isEqualTo("login@example.com");
    }

    @Test
    void duplicateEmailIsRejectedCaseInsensitively() {
        authService.signup(new SignupRequest("duplicate@example.com", "password123", "First User"));

        assertThatThrownBy(() -> authService.signup(new SignupRequest(
                "DUPLICATE@example.com", "different123", "Second User")))
                .isInstanceOfSatisfying(BusinessException.class,
                        exception -> assertThat(exception.errorCode()).isEqualTo(ErrorCode.EMAIL_ALREADY_EXISTS));
    }

    @Test
    void wrongPasswordIsRejectedWithoutRevealingWhichCredentialFailed() {
        authService.signup(new SignupRequest("wrong@example.com", "password123", "Wrong User"));

        assertThatThrownBy(() -> authService.login(new LoginRequest("wrong@example.com", "wrong-password")))
                .isInstanceOfSatisfying(BusinessException.class,
                        exception -> assertThat(exception.errorCode()).isEqualTo(ErrorCode.INVALID_CREDENTIALS));
        assertThatThrownBy(() -> authService.login(new LoginRequest("missing@example.com", "wrong-password")))
                .isInstanceOfSatisfying(BusinessException.class,
                        exception -> assertThat(exception.errorCode()).isEqualTo(ErrorCode.INVALID_CREDENTIALS));
    }
}
