package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.Ingredient;

/** A small, public-safe ingredient payload for recipe-composer typeahead. */
public record IngredientSuggestionResponse(Integer id, String name, String defaultUnit, String imageUrl) {
    public static IngredientSuggestionResponse from(Ingredient ingredient) {
        return from(ingredient, ingredient.getIngredientName());
    }

    public static IngredientSuggestionResponse from(Ingredient ingredient, String displayName) {
        return new IngredientSuggestionResponse(
                ingredient.getIngredientId(), displayName, ingredient.getDefaultUnit(),
                ingredient.getImageUrl());
    }
}
