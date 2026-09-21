package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;

class IbmMealPlannerRecommendationServiceTests {

    @Test
    void normalizesGoalsCorrectly() {
        assertEquals("LOSE_WEIGHT", IbmMealPlannerRecommendationService.normalizeGoal("LOSE_WEIGHT"));
        assertEquals("LOSE_WEIGHT", IbmMealPlannerRecommendationService.normalizeGoal("lose_weight"));
        assertEquals("MAINTAIN_HEALTH", IbmMealPlannerRecommendationService.normalizeGoal("MAINTAIN_HEALTH"));
        assertEquals("MAINTAIN_HEALTH", IbmMealPlannerRecommendationService.normalizeGoal(null));
        assertEquals("MAINTAIN_HEALTH", IbmMealPlannerRecommendationService.normalizeGoal("UNKNOWN"));
    }

    @Test
    void ranksMealsForWeightLossFavoringProteinDensityAndLowerCalories() {
        // High calorie, low protein meal (unfavorable for weight loss)
        PlannerMeal heavyMeal = new PlannerMeal();
        heavyMeal.setNameEn("Fried Pork with Fat Rice");
        heavyMeal.setCalories(new BigDecimal("800"));
        heavyMeal.setProteinGrams(new BigDecimal("15"));
        WeeklyMealRecommendation heavyRec = new WeeklyMealRecommendation();
        heavyRec.setPlannerMeal(heavyMeal);
        heavyRec.setRecommendationId(1);
        heavyRec.setSortOrder(1);

        // High protein, moderate calorie meal (ideal for weight loss)
        PlannerMeal leanMeal = new PlannerMeal();
        leanMeal.setNameEn("Grilled Chicken Breast & Steamed Veggies");
        leanMeal.setCalories(new BigDecimal("380"));
        leanMeal.setProteinGrams(new BigDecimal("42"));
        WeeklyMealRecommendation leanRec = new WeeklyMealRecommendation();
        leanRec.setPlannerMeal(leanMeal);
        leanRec.setRecommendationId(2);
        leanRec.setSortOrder(2);

        var ranked = IbmMealPlannerRecommendationService.deterministicRank(
                List.of(heavyRec, leanRec), "LOSE_WEIGHT");

        assertEquals(2, ranked.size());
        assertEquals("Grilled Chicken Breast & Steamed Veggies", ranked.getFirst().getPlannerMeal().getNameEn());
    }

    @Test
    void ranksBalancedMealAboveLeanLowCalorieMealForMaintenance() {
        PlannerMeal lean = new PlannerMeal();
        lean.setCalories(new BigDecimal("320"));
        lean.setProteinGrams(new BigDecimal("40"));
        lean.setCarbsGrams(new BigDecimal("10"));
        lean.setFatGrams(new BigDecimal("5"));
        WeeklyMealRecommendation leanRec = new WeeklyMealRecommendation();
        leanRec.setPlannerMeal(lean);
        leanRec.setSortOrder(1);

        PlannerMeal balanced = new PlannerMeal();
        balanced.setCalories(new BigDecimal("500"));
        balanced.setProteinGrams(new BigDecimal("25"));
        balanced.setCarbsGrams(new BigDecimal("55"));
        balanced.setFatGrams(new BigDecimal("15"));
        WeeklyMealRecommendation balancedRec = new WeeklyMealRecommendation();
        balancedRec.setPlannerMeal(balanced);
        balancedRec.setSortOrder(2);

        var ranked = IbmMealPlannerRecommendationService.deterministicRank(
                List.of(leanRec, balancedRec), "MAINTAIN_HEALTH");
        assertEquals(balancedRec, ranked.getFirst());
    }

    @Test
    void enrichesEmptyNotesWithGoalRationale() {
        AiUserHealthProfileService profileService = mock(AiUserHealthProfileService.class);
        var service = new IbmMealPlannerRecommendationService(
                profileService, "https://ibm.local", "https://iam.local", "", "", "ibm/granite-3-3-8b-instruct");

        PlannerMeal meal = new PlannerMeal();
        meal.setNameEn("Salmon & Broccoli");
        meal.setCalories(new BigDecimal("450"));
        meal.setProteinGrams(new BigDecimal("35"));
        WeeklyMealRecommendation rec = new WeeklyMealRecommendation();
        rec.setPlannerMeal(meal);
        rec.setRecommendationId(10);
        rec.setSortOrder(1);

        var result = service.rank(null, "LOSE_WEIGHT", List.of(rec, rec));
        assertNotNull(result.getFirst().getNote());
        assertTrue(result.getFirst().getNote().contains("Weight-loss match"));
        assertTrue(result.getFirst().getNote().contains("protein"));

        service.rank(null, "MAINTAIN_HEALTH", List.of(rec, rec));
        assertTrue(rec.getNote().contains("Maintenance match"));
        assertTrue(!rec.getNote().contains("Weight-loss match"));
    }

    @Test
    void clinicalAutoFillUsesDistinctFreshMealsWhenTheCatalogueIsLargeEnough() {
        AiUserHealthProfileService profileService = mock(AiUserHealthProfileService.class);
        var service = new IbmMealPlannerRecommendationService(
                profileService, "https://ibm.local", "https://iam.local", "", "", "test-model");
        List<PlannerMeal> meals = java.util.stream.IntStream.rangeClosed(1, 8)
                .mapToObj(id -> plannerMeal(id, "Meal " + id))
                .toList();
        LocalDate date = LocalDate.of(2026, 9, 21);

        var result = service.synthesizeClinicalPlan(
                List.of(date),
                Map.of(date, List.of("BREAKFAST", "LUNCH", "DINNER", "SNACK")),
                meals,
                1800,
                2200,
                "MAINTAIN_HEALTH",
                "en",
                Set.of(1, 2, 3, 4));

        Set<Integer> selectedIds = result.selections().stream()
                .map(selection -> selection.selectedMeal().getPlannerMealId())
                .collect(java.util.stream.Collectors.toSet());
        assertEquals(4, selectedIds.size());
        assertTrue(selectedIds.stream().noneMatch(Set.of(1, 2, 3, 4)::contains));
    }

    private static PlannerMeal plannerMeal(int id, String name) {
        PlannerMeal meal = new PlannerMeal();
        meal.setPlannerMealId(id);
        meal.setNameEn(name);
        meal.setCategoryEn("Healthy meal");
        meal.setCalories(new BigDecimal("220"));
        meal.setProteinGrams(new BigDecimal("20"));
        meal.setCarbsGrams(new BigDecimal("28"));
        meal.setFatGrams(new BigDecimal("7"));
        meal.setActive(true);
        return meal;
    }
}
