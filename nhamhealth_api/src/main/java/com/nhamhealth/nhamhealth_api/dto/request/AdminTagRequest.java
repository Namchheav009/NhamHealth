package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record AdminTagRequest(
        @NotBlank(message = "Tag name is required")
        @Size(max = 100, message = "Tag name must not exceed 100 characters")
        String tagName,
        @NotBlank(message = "Tag type is required")
        @Pattern(regexp = "(?i)NUTRITION|DIET|HEALTH|LIFESTYLE", message = "Choose a valid tag type")
        String tagScope,
        @Size(max = 255, message = "Description must not exceed 255 characters")
        String description,
        Boolean active) {
}
