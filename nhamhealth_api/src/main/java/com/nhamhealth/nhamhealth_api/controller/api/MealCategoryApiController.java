package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.MealCategoryResponse;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.MealCategoryTranslation;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.MealCategoryTranslationRepository;

@RestController
@RequestMapping("/api/v1/meal-categories")
public class MealCategoryApiController {

    private final MealCategoryRepository mealCategoryRepository;
    private final MealCategoryTranslationRepository mealCategoryTranslationRepository;

    public MealCategoryApiController(
            MealCategoryRepository mealCategoryRepository,
            MealCategoryTranslationRepository mealCategoryTranslationRepository) {
        this.mealCategoryRepository = mealCategoryRepository;
        this.mealCategoryTranslationRepository = mealCategoryTranslationRepository;
    }

    /** Returns only active categories, in the order configured by the admin, localized by lang. */
    @GetMapping
    public ResponseEntity<List<MealCategoryResponse>> activeMealCategories(
            @RequestParam(defaultValue = "en") String lang) {
        String normalizedLang = "km".equalsIgnoreCase(lang == null ? "" : lang.trim()) ? "km" : "en";
        List<MealCategory> categories = mealCategoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc();
        Map<Integer, MealCategoryTranslation> kmTranslations = mealCategoryTranslationRepository
                .findByLanguageCode("km")
                .stream()
                .collect(Collectors.toMap(t -> t.getCategory().getCategoryId(), Function.identity(), (a, b) -> a));

        List<MealCategoryResponse> response = categories.stream().map(cat -> {
            MealCategoryTranslation km = kmTranslations.get(cat.getCategoryId());
            String kmName = km != null && km.getName() != null && !km.getName().isBlank() ? km.getName().trim() : null;
            String displayName = "km".equals(normalizedLang) && kmName != null ? kmName : cat.getCategoryName();
            return new MealCategoryResponse(cat.getCategoryId(), displayName, kmName);
        }).toList();
        return ResponseEntity.ok(response);
    }
}
