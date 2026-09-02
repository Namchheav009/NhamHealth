package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.nhamhealth.nhamhealth_api.dto.response.MealDetailResponse;
import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.MealIngredient;
import com.nhamhealth.nhamhealth_api.entity.RecipeStep;
import com.nhamhealth.nhamhealth_api.repository.meal.MealIngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealNutritionRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeStepRepository;

class MealApiControllerTests {

    @Test
    void returnsOrderedIngredientsAndCookingStepsForPublishedMeal() {
        MealRepository meals = mock(MealRepository.class);
        MealIngredientRepository ingredients = mock(MealIngredientRepository.class);
        MealNutritionRepository nutrition = mock(MealNutritionRepository.class);
        RecipeStepRepository steps = mock(RecipeStepRepository.class);
        Meal meal = mock(Meal.class);
        MealCategory category = mock(MealCategory.class);
        MealIngredient mealIngredient = mock(MealIngredient.class);
        Ingredient ingredient = mock(Ingredient.class);
        RecipeStep recipeStep = mock(RecipeStep.class);

        when(meals.findById(42)).thenReturn(Optional.of(meal));
        when(meal.getIsPublished()).thenReturn(true);
        when(meal.getMealId()).thenReturn(42);
        when(meal.getMealName()).thenReturn("Bai Sach Chrouk");
        when(meal.getCategory()).thenReturn(category);
        when(category.getCategoryId()).thenReturn(5);
        when(category.getCategoryName()).thenReturn("Breakfast");
        when(meal.getMainImageUrl()).thenReturn("/uploads/meals/pork-rice.jpg");
        when(meal.getCaloriesCached()).thenReturn(new BigDecimal("470"));
        when(meal.getDescription()).thenReturn("A nourishing choice for your day.");
        when(meal.getCookingTimeMinutes()).thenReturn(35);
        when(meal.getDifficulty()).thenReturn("Medium");
        when(meal.getServings()).thenReturn(1);

        when(ingredients.findByMealMealIdOrderByDisplayOrderAsc(42))
                .thenReturn(List.of(mealIngredient));
        when(mealIngredient.getIngredient()).thenReturn(ingredient);
        when(ingredient.getIngredientId()).thenReturn(9);
        when(ingredient.getIngredientName()).thenReturn("Pork shoulder");
        when(ingredient.getDescription()).thenReturn("Thinly sliced");
        when(ingredient.getImageUrl()).thenReturn("/uploads/ingredients/pork.jpg");
        when(mealIngredient.getQuantity()).thenReturn(new BigDecimal("200"));
        when(mealIngredient.getUnit()).thenReturn("g");
        when(mealIngredient.getPreparationNote()).thenReturn("marinated");
        when(nutrition.findByMealMealIdOrderByNutrientDisplayOrderAsc(42)).thenReturn(List.of());

        when(steps.findByMealMealIdOrderByStepNumberAsc(42)).thenReturn(List.of(recipeStep));
        when(recipeStep.getStepNumber()).thenReturn(1);
        when(recipeStep.getInstruction()).thenReturn("Season and rest for 20 minutes.");

        MealApiController controller = new MealApiController(meals, ingredients, nutrition, steps);
        ResponseEntity<MealDetailResponse> response = controller.publishedMeal(42);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        MealDetailResponse detail = response.getBody();
        assertNotNull(detail);
        assertEquals("Pork shoulder", detail.ingredients().getFirst().name());
        assertEquals(new BigDecimal("200"), detail.ingredients().getFirst().quantity());
        assertEquals("Season and rest for 20 minutes.", detail.steps().getFirst().instruction());
    }
}
