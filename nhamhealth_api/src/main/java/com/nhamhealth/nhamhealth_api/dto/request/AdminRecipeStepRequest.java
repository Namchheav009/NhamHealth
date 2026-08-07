package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminRecipeStepRequest(
        @Size(max = 150) String title,
        @NotBlank @Size(max = 255) String instruction,
        @NotBlank @Size(max = 255) String imageUrl) {
}
