package com.nhamhealth.nhamhealth_api.dto.response;

public record PhoneVerificationResponse(
        boolean success,
        String message,
        String phone,
        boolean verified
        ) {

}
