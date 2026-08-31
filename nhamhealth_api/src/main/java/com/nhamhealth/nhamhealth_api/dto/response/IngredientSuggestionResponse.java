package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.Ingredient;

/** A small, public-safe ingredient payload for recipe-composer typeahead. */
public record IngredientSuggestionResponse(Integer id, String name, String defaultUnit) {
    public static IngredientSuggestionResponse from(Ingredient ingredient) {
        return new IngredientSuggestionResponse(
                ingredient.getIngredientId(), ingredient.getIngredientName(), ingredient.getDefaultUnit());
    }
}
