package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CommunityTagRequest(
        @NotBlank(message = "Tag name is required")
        @Size(max = 100, message = "Tag name must not exceed 100 characters")
        String name) {
}
