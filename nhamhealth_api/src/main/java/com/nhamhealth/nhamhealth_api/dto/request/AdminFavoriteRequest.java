package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record AdminFavoriteRequest(
        @NotBlank String kind,
        @NotNull Integer userId,
        @NotNull Integer contentId) {
}
