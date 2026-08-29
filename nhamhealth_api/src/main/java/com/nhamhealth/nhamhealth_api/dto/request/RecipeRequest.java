package com.nhamhealth.nhamhealth_api.dto.request;

import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record RecipeRequest(
        @NotBlank @Size(max = 150) String recipeName,
        @Size(max = 4000) String description,
        @Positive Integer cookingTimeMinutes,
        @Positive Integer servings,
        @Size(max = 20) String difficulty,
        List<Integer> tagIds,
        List<@Valid RecipeIngredientRequest> ingredients,
        List<@Valid RecipeStepRequest> steps) { }
