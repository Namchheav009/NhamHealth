package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record RefreshTokenRequest(
        @NotBlank(message = "Refresh token is required") String refreshToken) {
    @Override public String toString() { return "RefreshTokenRequest[refreshToken=[REDACTED]]"; }
}
