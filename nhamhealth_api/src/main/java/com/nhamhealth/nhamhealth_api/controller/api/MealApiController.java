package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.MealDetailResponse;
import com.nhamhealth.nhamhealth_api.dto.response.MealResponse;
import com.nhamhealth.nhamhealth_api.repository.meal.MealRepository;
import com.nhamhealth.nhamhealth_api.service.meal.MealTranslationService;

@RestController
@RequestMapping({ "/api/v1/meals", "/api/meals" })
public class MealApiController {

    private final MealRepository mealRepository;
    private final MealTranslationService translations;

    public MealApiController(MealRepository mealRepository, MealTranslationService translations) {
        this.mealRepository = mealRepository;
        this.translations = translations;
    }

    /** Returns published meals from the Supabase-backed PostgreSQL database. */
    @GetMapping
    @Cacheable(value = "meals", key = "{#keyword == null ? '' : #keyword.trim().toLowerCase(), #categoryId, #lang == null ? 'en' : #lang}")
    public ResponseEntity<List<MealResponse>> publishedMeals(
            @RequestParam(defaultValue = "") String keyword,
            @RequestParam(defaultValue = "0") Integer categoryId,
            @RequestParam(defaultValue = "en") String lang) {
        var meals = mealRepository.findPublishedMeals(keyword.trim(), categoryId);
        return ResponseEntity.ok(translations.publishedMeals(meals, lang));
    }

    @GetMapping("/{mealId}")
    @Cacheable(value = "mealDetail", key = "{#mealId, #lang == null ? 'en' : #lang}")
    public ResponseEntity<MealDetailResponse> publishedMeal(@PathVariable Integer mealId,
            @RequestParam(defaultValue = "en") String lang) {
        return translations.detail(mealId, lang)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
