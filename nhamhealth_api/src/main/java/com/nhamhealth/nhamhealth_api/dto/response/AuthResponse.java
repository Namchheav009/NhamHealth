package com.nhamhealth.nhamhealth_api.dto.response;

public record AuthResponse(
        String accessToken,
        String tokenType,
        long expiresIn,
        String refreshToken,
        long refreshExpiresIn,
        AuthenticatedUserResponse user) {
    @Override
    public String toString() {
        return "AuthResponse[accessToken=[REDACTED], tokenType=" + tokenType
                + ", expiresIn=" + expiresIn + ", refreshToken=[REDACTED], refreshExpiresIn="
                + refreshExpiresIn + ", user=" + user + "]";
    }
}
