package com.nhamhealth.nhamhealth_api.auth.dto;

public record AuthenticatedUserResponse(
        Integer userId,
        String email,
        String role) {
}
