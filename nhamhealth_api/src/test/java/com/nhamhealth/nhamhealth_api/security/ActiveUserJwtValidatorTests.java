package com.nhamhealth.nhamhealth_api.security;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.TimeUnit;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;

import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

class ActiveUserJwtValidatorTests {

    private UserRepository userRepository;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
    }

    private Jwt createJwt(Integer userId, Integer authVersion) {
        Jwt.Builder builder = Jwt.withTokenValue("mock-token")
                .header("alg", "HS256")
                .issuer("nhamhealth-api")
                .issuedAt(Instant.now())
                .expiresAt(Instant.now().plusSeconds(3600))
                .subject("test@example.com");

        if (userId != null) {
            builder.claim("userId", userId);
        }
        if (authVersion != null) {
            builder.claim("authVersion", authVersion);
        }
        return builder.build();
    }

    private User createMockUser(String status, boolean isVerified, int authVersion) {
        User user = new User();
        user.setStatus(status);
        user.setIsVerified(isVerified);
        user.setAuthVersion(authVersion);
        return user;
    }

    @Test
    void validate_missingClaims_returnsFailure() {
        ActiveUserJwtValidator validator = new ActiveUserJwtValidator(userRepository);

        OAuth2TokenValidatorResult noUserId = validator.validate(createJwt(null, 1));
        assertThat(noUserId.hasErrors()).isTrue();

        OAuth2TokenValidatorResult noAuthVersion = validator.validate(createJwt(1, null));
        assertThat(noAuthVersion.hasErrors()).isTrue();
    }

    @Test
    void validate_userNotFound_returnsFailure() {
        ActiveUserJwtValidator validator = new ActiveUserJwtValidator(userRepository);
        when(userRepository.findById(99)).thenReturn(Optional.empty());

        OAuth2TokenValidatorResult result = validator.validate(createJwt(99, 1));
        assertThat(result.hasErrors()).isTrue();
        assertThat(result.getErrors()).anyMatch(e -> "invalid_token".equals(e.getErrorCode()));
    }

    @Test
    void validate_userSuspended_returnsFailure() {
        ActiveUserJwtValidator validator = new ActiveUserJwtValidator(userRepository);
        User suspendedUser = createMockUser("SUSPENDED", true, 1);
        when(userRepository.findById(1)).thenReturn(Optional.of(suspendedUser));

        OAuth2TokenValidatorResult result = validator.validate(createJwt(1, 1));
        assertThat(result.hasErrors()).isTrue();
    }

    @Test
    void validate_userNotVerified_returnsFailure() {
        ActiveUserJwtValidator validator = new ActiveUserJwtValidator(userRepository);
        User unverifiedUser = createMockUser("ACTIVE", false, 1);
        when(userRepository.findById(1)).thenReturn(Optional.of(unverifiedUser));

        OAuth2TokenValidatorResult result = validator.validate(createJwt(1, 1));
        assertThat(result.hasErrors()).isTrue();
    }

    @Test
    void validate_authVersionMismatch_returnsFailure() {
        ActiveUserJwtValidator validator = new ActiveUserJwtValidator(userRepository);
        User user = createMockUser("ACTIVE", true, 2);
        when(userRepository.findById(1)).thenReturn(Optional.of(user));

        OAuth2TokenValidatorResult result = validator.validate(createJwt(1, 1));
        assertThat(result.hasErrors()).isTrue();
    }

    @Test
    void validate_activeVerifiedMatchingUser_returnsSuccess() {
        ActiveUserJwtValidator validator = new ActiveUserJwtValidator(userRepository);
        User user = createMockUser("ACTIVE", true, 1);
        when(userRepository.findById(1)).thenReturn(Optional.of(user));

        OAuth2TokenValidatorResult result = validator.validate(createJwt(1, 1));
        assertThat(result.hasErrors()).isFalse();
    }

    @Test
    void validate_usesCacheWithinTtl_avoidsDuplicateDbQueries() {
        ActiveUserJwtValidator validator = new ActiveUserJwtValidator(userRepository, 5, TimeUnit.SECONDS);
        User user = createMockUser("ACTIVE", true, 3);
        when(userRepository.findById(42)).thenReturn(Optional.of(user));

        // First call queries DB
        OAuth2TokenValidatorResult result1 = validator.validate(createJwt(42, 3));
        assertThat(result1.hasErrors()).isFalse();

        // Second call within 5s uses cache
        OAuth2TokenValidatorResult result2 = validator.validate(createJwt(42, 3));
        assertThat(result2.hasErrors()).isFalse();

        // Third call within 5s uses cache
        OAuth2TokenValidatorResult result3 = validator.validate(createJwt(42, 3));
        assertThat(result3.hasErrors()).isFalse();

        // Verify userRepository.findById was only called once!
        verify(userRepository, times(1)).findById(42);
    }
}
