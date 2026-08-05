package com.nhamhealth.nhamhealth_api.dto;

public record AuthenticatedUserResponse(
        Integer id,
        String email,
        String role) {
}
