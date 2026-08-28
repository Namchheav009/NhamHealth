package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record RecipeStepRequest(String title, @NotBlank String instruction) { }
