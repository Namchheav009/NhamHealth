package com.nhamhealth.nhamhealth_api.dto.request;

import java.util.List;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;

public record AiIngredientReanalysisRequest(
        @NotEmpty @Size(max = 30) List<@Valid FoodVisionComponent> ingredients) {

    public AiIngredientReanalysisRequest {
        ingredients = ingredients == null ? List.of() : List.copyOf(ingredients);
    }
}
