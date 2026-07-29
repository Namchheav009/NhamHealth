package com.nhamhealth.nhamhealth_api.dto;

public record AuthResponse(
        String accessToken,
        String tokenType,
        long expiresIn,
        AuthenticatedUserResponse user) {
}
