package com.nhamhealth.nhamhealth_api.dto.response;

public record LoginChallengeResponse(boolean otpRequired, String email, String message) { }
