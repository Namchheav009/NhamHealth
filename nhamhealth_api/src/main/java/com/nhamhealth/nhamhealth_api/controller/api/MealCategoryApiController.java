package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.MealCategoryResponse;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;

@RestController
@RequestMapping("/api/v1/meal-categories")
public class MealCategoryApiController {

    private final MealCategoryRepository mealCategoryRepository;

    public MealCategoryApiController(MealCategoryRepository mealCategoryRepository) {
        this.mealCategoryRepository = mealCategoryRepository;
    }

    /** Returns only active categories, in the order configured by the admin. */
    @GetMapping
    public ResponseEntity<List<MealCategoryResponse>> activeMealCategories() {
        List<MealCategoryResponse> categories = mealCategoryRepository
                .findAllByIsActiveTrueOrderBySortOrderAsc()
                .stream()
                .map(MealCategoryResponse::from)
                .toList();
        return ResponseEntity.ok(categories);
    }
}
