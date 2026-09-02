package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminRecipeStepRequest(
        @NotBlank @Size(max = 255) String instruction) {
}
