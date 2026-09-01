package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.MealDetailResponse;
import com.nhamhealth.nhamhealth_api.dto.response.MealResponse;
import com.nhamhealth.nhamhealth_api.repository.meal.MealIngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealNutritionRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeStepRepository;

@RestController
@RequestMapping("/api/v1/meals")
public class MealApiController {

    private final MealRepository mealRepository;
    private final MealIngredientRepository mealIngredientRepository;
    private final MealNutritionRepository mealNutritionRepository;
    private final RecipeStepRepository recipeStepRepository;

    public MealApiController(MealRepository mealRepository,
            MealIngredientRepository mealIngredientRepository,
            MealNutritionRepository mealNutritionRepository,
            RecipeStepRepository recipeStepRepository) {
        this.mealRepository = mealRepository;
        this.mealIngredientRepository = mealIngredientRepository;
        this.mealNutritionRepository = mealNutritionRepository;
        this.recipeStepRepository = recipeStepRepository;
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

    @GetMapping("/{mealId}")
    public ResponseEntity<MealDetailResponse> publishedMeal(@PathVariable Integer mealId) {
        return mealRepository.findById(mealId)
                .filter(meal -> Boolean.TRUE.equals(meal.getIsPublished()))
                .map(meal -> MealDetailResponse.from(
                        meal,
                        mealIngredientRepository.findByMealMealIdOrderByDisplayOrderAsc(mealId),
                        mealNutritionRepository.findByMealMealIdOrderByNutrientDisplayOrderAsc(mealId),
                        recipeStepRepository.findByMealMealIdOrderByStepNumberAsc(mealId)))
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
