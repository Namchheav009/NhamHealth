package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.entity.IngredientTranslation;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.IngredientTranslationRepository;

class IngredientApiControllerTests {

    @Test
    void khmerSearchReturnsLocalizedNameAndIngredientImage() {
        IngredientRepository ingredients = mock(IngredientRepository.class);
        IngredientTranslationRepository translations = mock(IngredientTranslationRepository.class);
        Ingredient ingredient = mock(Ingredient.class);
        IngredientTranslation translation = mock(IngredientTranslation.class);

        when(ingredient.getIngredientId()).thenReturn(7);
        when(ingredient.getIngredientName()).thenReturn("Greek yogurt");
        when(ingredient.getDefaultUnit()).thenReturn("g");
        when(ingredient.getImageUrl()).thenReturn("/uploads/ingredients/greek-yogurt.webp");
        when(translation.getIngredient()).thenReturn(ingredient);
        when(translation.getName()).thenReturn("យ៉ាអួក្រិក");
        when(translations.findTop20ByLanguageCodeAndNameContainingIgnoreCaseOrderByNameAsc(
                "km", "យ៉ាអួក្រិក")).thenReturn(List.of(translation));
        when(ingredients.findTop20ByIngredientNameContainingIgnoreCaseOrderByIngredientNameAsc("យ៉ាអួក្រិក"))
                .thenReturn(List.of());

        var response = new IngredientApiController(ingredients, translations)
                .search("យ៉ាអួក្រិក", "km");

        assertEquals(1, response.size());
        assertEquals("យ៉ាអួក្រិក", response.getFirst().name());
        assertEquals("/uploads/ingredients/greek-yogurt.webp", response.getFirst().imageUrl());
    }
}
