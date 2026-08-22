package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.MealResponse;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;

@RestController
@RequestMapping("/api/v1/meals")
public class MealApiController {

    private final MealRepository mealRepository;

    public MealApiController(MealRepository mealRepository) {
        this.mealRepository = mealRepository;
    }

    /** Returns published meals from the Supabase-backed PostgreSQL database. */
    @GetMapping
    public ResponseEntity<List<MealResponse>> publishedMeals(
            @org.springframework.web.bind.annotation.RequestParam(defaultValue = "") String keyword,
            @org.springframework.web.bind.annotation.RequestParam(defaultValue = "0") Integer categoryId) {
        List<MealResponse> meals = mealRepository
                .findPublishedMeals(keyword.trim(), categoryId)
                .stream()
                .map(MealResponse::from)
                .toList();
        return ResponseEntity.ok(meals);
    }
}
