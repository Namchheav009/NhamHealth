package com.nhamhealth.nhamhealth_api.security;

import java.util.concurrent.TimeUnit;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

import com.github.benmanes.caffeine.cache.Cache;
import com.github.benmanes.caffeine.cache.Caffeine;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

/**
 * Re-checks the mutable account controls stored in the database for every API
 * request. A signed JWT alone is not enough because an administrator may have
 * suspended the account or invalidated its sessions after the token was issued.
 */
@Component
public class ActiveUserJwtValidator implements OAuth2TokenValidator<Jwt> {

    private static final OAuth2Error INVALID_ACCOUNT = new OAuth2Error(
            "invalid_token",
            "The user account or session is no longer active",
            null);

    private final UserRepository userRepository;

    // Short-lived local cache (5 seconds) to absorb bursts of simultaneous
    // API calls from the same client session (e.g. parallel requests on page load)
    // without hammering the connection pool, while ensuring account revocations
    // take effect promptly.
    private final Cache<Integer, UserValidationSnapshot> validationCache;

    @Autowired
    public ActiveUserJwtValidator(UserRepository userRepository) {
        this(userRepository, 5, TimeUnit.SECONDS);
    }

    ActiveUserJwtValidator(UserRepository userRepository, long duration, TimeUnit unit) {
        this.userRepository = userRepository;
        this.validationCache = Caffeine.newBuilder()
                .expireAfterWrite(duration, unit)
                .maximumSize(2000)
                .build();
    }

    @Override
    public OAuth2TokenValidatorResult validate(Jwt jwt) {
        Integer userId = integerClaim(jwt, "userId");
        Integer tokenAuthVersion = integerClaim(jwt, "authVersion");
        if (userId == null || tokenAuthVersion == null) {
            return OAuth2TokenValidatorResult.failure(INVALID_ACCOUNT);
        }

        UserValidationSnapshot snapshot = validationCache.get(userId, this::loadSnapshot);
        if (snapshot == null
                || !snapshot.active()
                || !Boolean.TRUE.equals(snapshot.verified())
                || snapshot.authVersion() != tokenAuthVersion) {
            validationCache.invalidate(userId);
            return OAuth2TokenValidatorResult.failure(INVALID_ACCOUNT);
        }

        return OAuth2TokenValidatorResult.success();
    }

    private UserValidationSnapshot loadSnapshot(Integer userId) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) {
            return null;
        }
        int authVersion = user.getAuthVersion() == null ? 0 : user.getAuthVersion();
        boolean active = "ACTIVE".equalsIgnoreCase(user.getStatus());
        boolean verified = Boolean.TRUE.equals(user.getIsVerified());
        return new UserValidationSnapshot(active, verified, authVersion);
    }

    public void invalidateCache(Integer userId) {
        if (userId != null) {
            validationCache.invalidate(userId);
        }
    }

    public void clearCache() {
        validationCache.invalidateAll();
    }

    private Integer integerClaim(Jwt jwt, String name) {
        Object value = jwt.getClaim(name);
        if (value instanceof Number number) {
            return number.intValue();
        }
        if (value instanceof String text) {
            try {
                return Integer.valueOf(text);
            } catch (NumberFormatException ignored) {
                return null;
            }
        }
        return null;
    }

    record UserValidationSnapshot(boolean active, Boolean verified, int authVersion) {}
}
