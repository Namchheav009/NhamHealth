package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminMealCategoryRequest(
        @NotBlank @Size(max = 50) String categoryName,
        @Size(max = 255) String description,
        boolean active,
        @Min(0) @Max(10000) Integer sortOrder) {
}
