package com.nhamhealth.nhamhealth_api.security;

import org.springframework.security.oauth2.core.OAuth2Error;
import org.springframework.security.oauth2.core.OAuth2TokenValidator;
import org.springframework.security.oauth2.core.OAuth2TokenValidatorResult;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.stereotype.Component;

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

    public ActiveUserJwtValidator(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public OAuth2TokenValidatorResult validate(Jwt jwt) {
        Integer userId = integerClaim(jwt, "userId");
        Integer tokenAuthVersion = integerClaim(jwt, "authVersion");
        if (userId == null || tokenAuthVersion == null) {
            return OAuth2TokenValidatorResult.failure(INVALID_ACCOUNT);
        }

        User user = userRepository.findById(userId).orElse(null);
        int currentAuthVersion = user == null || user.getAuthVersion() == null
                ? 0
                : user.getAuthVersion();
        if (user == null
                || !"ACTIVE".equalsIgnoreCase(user.getStatus())
                || !Boolean.TRUE.equals(user.getIsVerified())
                || currentAuthVersion != tokenAuthVersion) {
            return OAuth2TokenValidatorResult.failure(INVALID_ACCOUNT);
        }

        return OAuth2TokenValidatorResult.success();
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
}
