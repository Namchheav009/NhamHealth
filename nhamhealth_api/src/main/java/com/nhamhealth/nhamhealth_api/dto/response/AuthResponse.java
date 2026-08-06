package com.nhamhealth.nhamhealth_api.dto.response;

public record AuthResponse(
        String accessToken,
        String tokenType,
        long expiresIn,
        AuthenticatedUserResponse user) {
}
