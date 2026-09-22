package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.IngredientSuggestionResponse;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.IngredientTranslationRepository;

/** Read-only ingredient catalog search used by app clients. */
@RestController
@RequestMapping("/api/v1/ingredients")
public class IngredientApiController {
    private final IngredientRepository ingredients;
    private final IngredientTranslationRepository translations;

    public IngredientApiController(
            IngredientRepository ingredients,
            IngredientTranslationRepository translations) {
        this.ingredients = ingredients;
        this.translations = translations;
    }

    @GetMapping
    public List<IngredientSuggestionResponse> search(
            @RequestParam(value = "query", required = false) String query,
            @RequestParam(value = "lang", required = false) String lang) {
        String normalized = query == null ? "" : query.trim();
        if (!normalized.isEmpty() && "km".equalsIgnoreCase(lang)) {
            List<IngredientSuggestionResponse> result = new ArrayList<>();
            Set<Integer> includedIds = new HashSet<>();
            translations.findTop20ByLanguageCodeAndNameContainingIgnoreCaseOrderByNameAsc("km", normalized)
                    .forEach(translation -> {
                        if (includedIds.add(translation.getIngredient().getIngredientId())) {
                            result.add(IngredientSuggestionResponse.from(
                                    translation.getIngredient(), translation.getName()));
                        }
                    });
            ingredients.findTop20ByIngredientNameContainingIgnoreCaseOrderByIngredientNameAsc(normalized)
                    .forEach(ingredient -> {
                        if (result.size() < 20 && includedIds.add(ingredient.getIngredientId())) {
                            result.add(IngredientSuggestionResponse.from(ingredient));
                        }
                    });
            return result.stream().limit(20).toList();
        }

        return (normalized.isEmpty()
                ? ingredients.findAllByOrderByIngredientNameAsc().stream().limit(12).toList()
                : ingredients.findTop20ByIngredientNameContainingIgnoreCaseOrderByIngredientNameAsc(normalized))
                .stream()
                .map(IngredientSuggestionResponse::from)
                .toList();
    }
}
