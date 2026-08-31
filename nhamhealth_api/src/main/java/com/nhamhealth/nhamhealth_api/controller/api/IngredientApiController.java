package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.IngredientSuggestionResponse;
import com.nhamhealth.nhamhealth_api.repository.IngredientRepository;

/** Read-only catalog search used by the Community meal-post composer. */
@RestController
@RequestMapping("/api/v1/ingredients")
public class IngredientApiController {
    private final IngredientRepository ingredients;

    public IngredientApiController(IngredientRepository ingredients) {
        this.ingredients = ingredients;
    }

    @GetMapping
    public List<IngredientSuggestionResponse> search(
            @RequestParam(value = "query", required = false) String query) {
        String normalized = query == null ? "" : query.trim();
        return (normalized.isEmpty()
                ? ingredients.findAllByOrderByIngredientNameAsc().stream().limit(12).toList()
                : ingredients.findTop20ByIngredientNameContainingIgnoreCaseOrderByIngredientNameAsc(normalized))
                .stream()
                .map(IngredientSuggestionResponse::from)
                .toList();
    }
}
