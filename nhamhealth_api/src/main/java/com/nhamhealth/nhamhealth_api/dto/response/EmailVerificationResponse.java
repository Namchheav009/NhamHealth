package com.nhamhealth.nhamhealth_api.dto.response;

public record EmailVerificationResponse(
        boolean success,
        String message,
        String email,
        boolean verified) {
}
