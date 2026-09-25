package com.nhamhealth.nhamhealth_api.service.meal;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;

class PlannerMealContentTests {
    @Test
    void splitsSemicolonLegacyIngredientsAndInstructions() {
        PlannerMeal meal = new PlannerMeal();
        meal.setIngredientsText("60g oats; 1 banana; 250ml milk; 1 tbsp peanut butter; 1 tsp chia seeds");
        meal.setInstructionsText("Add oats; Add milk; Simmer and serve");

        var ingredients = PlannerMealContent.ingredients(meal);
        assertEquals(5, ingredients.size());
        assertEquals("oats", ingredients.get(0).name());
        assertEquals("60", ingredients.get(0).quantity().toPlainString());
        assertEquals("g", ingredients.get(0).unit());
        assertEquals("banana", ingredients.get(1).name());
        assertEquals("piece", ingredients.get(1).unit());
        assertEquals(3, PlannerMealContent.instructions(meal).size());
    }
}
