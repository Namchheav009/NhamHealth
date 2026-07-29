package com.nhamhealth.nhamhealth_api.dto;

public record AuthenticatedUserResponse(
        Integer userId,
        String email,
        String role) {
}
