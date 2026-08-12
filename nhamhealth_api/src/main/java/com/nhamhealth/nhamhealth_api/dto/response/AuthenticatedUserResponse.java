package com.nhamhealth.nhamhealth_api.dto.response;

public record AuthenticatedUserResponse(
        Integer id,
        String email,
        String role,
        String fullName,
        String profileImageUrl) {
}
