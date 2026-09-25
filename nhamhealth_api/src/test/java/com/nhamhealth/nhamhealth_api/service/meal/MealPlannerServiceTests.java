package com.nhamhealth.nhamhealth_api.service.meal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.Set;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.MealPlanRequest;
import com.nhamhealth.nhamhealth_api.dto.request.MealPlanUpdateRequest;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.MealPlan;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.meal.MealPlanRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

class MealPlannerServiceTests {
    private MealPlanRepository plans;
    private PlannerMealRepository plannerMeals;
    private WeeklyMealRecommendationRepository recommendations;
    private UserRepository users;
    private MealPlannerService service;

    @BeforeEach
    void setUp() {
        plans = mock(MealPlanRepository.class);
        plannerMeals = mock(PlannerMealRepository.class);
        recommendations = mock(WeeklyMealRecommendationRepository.class);
        users = mock(UserRepository.class);
        service = new MealPlannerService(plans, plannerMeals, recommendations, users);
    }

    private PlannerMeal sampleMeal(Integer id) {
        PlannerMeal meal = new PlannerMeal();
        meal.setPlannerMealId(id);
        meal.setNameEn("Healthy Salmon");
        meal.setNameKm("ត្រីសាល់ម៉ុងសុខភាព");
        meal.setActive(true);
        MealCategory category = new MealCategory();
        category.setCategoryId(1);
        category.setCategoryName("Dinner");
        meal.setCategory(category);
        meal.setCalories(new BigDecimal("450"));
        meal.setProteinGrams(new BigDecimal("35"));
        meal.setCarbsGrams(new BigDecimal("10"));
        meal.setFatGrams(new BigDecimal("15"));
        meal.setIngredientsText("Salmon | 1 | fillet | ត្រីសាល់ម៉ុង");
        return meal;
    }

    @Test
    void addOrReplaceStoresMealOnAnyDay() {
        LocalDate customDate = LocalDate.of(2026, 9, 23); // Wednesday
        PlannerMeal meal = sampleMeal(10);
        when(plannerMeals.findById(10)).thenReturn(Optional.of(meal));
        when(users.getReferenceById(1)).thenReturn(new User());
        when(plans.findByUserUserIdAndPlanDateAndMealType(1, customDate, "LUNCH")).thenReturn(Optional.empty());
        when(plans.save(any(MealPlan.class))).thenAnswer(invocation -> {
            MealPlan saved = invocation.getArgument(0);
            saved.setMealPlanId(101);
            return saved;
        });

        MealPlanRequest request = new MealPlanRequest(
                customDate, "LUNCH", 10, new BigDecimal("1.5"), "MAINTAIN_HEALTH");
        var response = service.addOrReplace(1, request, "km");

        assertNotNull(response);
        assertEquals(101, response.planId());
        assertEquals("ត្រីសាល់ម៉ុងសុខភាព", response.mealName());
        assertEquals(new BigDecimal("1.5"), response.servings());
    }

    @Test
    void addOrReplaceRejectsMealOutsideSelectedWeightGoal() {
        LocalDate date = LocalDate.of(2026, 9, 23);
        PlannerMeal meal = sampleMeal(10);
        meal.setWeightGoals(Set.of("GAIN_WEIGHT"));
        when(plannerMeals.findById(10)).thenReturn(Optional.of(meal));

        MealPlanRequest request = new MealPlanRequest(
                date, "LUNCH", 10, BigDecimal.ONE, "LOSE_WEIGHT");

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class,
                () -> service.addOrReplace(1, request, "en"));
        assertEquals(400, error.getStatusCode().value());
        verify(plans, never()).save(any());
    }

    @Test
    void rangeLoadsDynamicDays() {
        LocalDate start = LocalDate.of(2026, 9, 20);
        LocalDate end = LocalDate.of(2026, 9, 22); // 3-day range
        MealPlan p1 = new MealPlan();
        p1.setMealPlanId(1);
        p1.setPlanDate(start);
        p1.setMealType("BREAKFAST");
        p1.setServings(BigDecimal.ONE);
        p1.setStatus("PLANNED");
        p1.setPlannerMeal(sampleMeal(5));

        when(plans.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(1, start, end))
                .thenReturn(List.of(p1));

        var result = service.range(1, start, end, "en");
        assertEquals(1, result.size());
        assertEquals("Healthy Salmon", result.getFirst().mealName());
    }

    @Test
    void updateModifiesMealWithoutAdminRecommendationConstraint() {
        MealPlan existing = new MealPlan();
        existing.setMealPlanId(50);
        existing.setPlanDate(LocalDate.of(2026, 9, 25));
        existing.setMealType("DINNER");
        existing.setServings(BigDecimal.ONE);
        existing.setStatus("PLANNED");
        existing.setPlannerMeal(sampleMeal(1));

        when(plans.findByMealPlanIdAndUserUserId(50, 1)).thenReturn(Optional.of(existing));
        when(plannerMeals.findById(20)).thenReturn(Optional.of(sampleMeal(20)));
        when(plans.save(any(MealPlan.class))).thenAnswer(invocation -> invocation.getArgument(0));

        MealPlanUpdateRequest request = new MealPlanUpdateRequest(
                null, 20, new BigDecimal("2"), "PLANNED", null, "MAINTAIN_HEALTH");
        var response = service.update(1, 50, request, "en");

        assertNotNull(response);
        assertEquals(20, response.plannerMealId());
        assertEquals(new BigDecimal("2"), response.servings());
    }

    @Test
    void rangeReturnsLocalizedInstructionsAndTagsForKhmer() {
        LocalDate date = LocalDate.of(2026, 9, 20);
        MealPlan plan = new MealPlan();
        plan.setMealPlanId(1);
        plan.setPlanDate(date);
        plan.setMealType("DINNER");
        plan.setServings(BigDecimal.ONE);
        plan.setStatus("PLANNED");

        PlannerMeal meal = sampleMeal(10);
        meal.setInstructionsText("Step 1: Pan fry salmon.");
        meal.setInstructionsTextKm("ជំហានទី ១៖ ចៀនត្រីសាល់ម៉ុង។");
        meal.setTagsText("Omega3, Keto");
        meal.setTagsTextKm("អូមេហ្គា៣, គីតូ");
        plan.setPlannerMeal(meal);

        when(plans.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(1, date, date))
                .thenReturn(List.of(plan));

        var kmResult = service.range(1, date, date, "km");
        assertEquals(1, kmResult.size());
        assertEquals(List.of("ជំហានទី ១៖ ចៀនត្រីសាល់ម៉ុង។"), kmResult.getFirst().instructions());
        assertEquals(List.of("អូមេហ្គា៣", "គីតូ"), kmResult.getFirst().tags());

        var enResult = service.range(1, date, date, "en");
        assertEquals(1, enResult.size());
        assertEquals(List.of("Step 1: Pan fry salmon."), enResult.getFirst().instructions());
        assertEquals(List.of("Omega3", "Keto"), enResult.getFirst().tags());
    }

    @Test
    void bulkAddOrReplaceStoresMultipleMealsInSingleCall() {
        LocalDate d1 = LocalDate.of(2026, 9, 21);
        LocalDate d2 = LocalDate.of(2026, 9, 22);
        PlannerMeal meal1 = sampleMeal(10);
        PlannerMeal meal2 = sampleMeal(20);

        when(plannerMeals.findById(10)).thenReturn(Optional.of(meal1));
        when(plannerMeals.findById(20)).thenReturn(Optional.of(meal2));
        when(users.getReferenceById(1)).thenReturn(new User());
        when(plans.findByUserUserIdAndPlanDateAndMealType(1, d1, "BREAKFAST")).thenReturn(Optional.empty());
        when(plans.findByUserUserIdAndPlanDateAndMealType(1, d2, "LUNCH")).thenReturn(Optional.empty());
        when(plans.save(any(MealPlan.class))).thenAnswer(invocation -> {
            MealPlan p = invocation.getArgument(0);
            p.setMealPlanId(999);
            return p;
        });

        List<MealPlanRequest> batch = List.of(
                new MealPlanRequest(d1, "BREAKFAST", 10, BigDecimal.ONE, "MAINTAIN_HEALTH"),
                new MealPlanRequest(d2, "LUNCH", 20, new BigDecimal("2.0"), "MAINTAIN_HEALTH"));

        var results = service.bulkAddOrReplace(1, batch, "en");

        assertEquals(2, results.size());
        assertEquals(d1, results.get(0).planDate());
        assertEquals("BREAKFAST", results.get(0).mealType());
        assertEquals(d2, results.get(1).planDate());
        assertEquals("LUNCH", results.get(1).mealType());
    }

    @Test
    void bulkDeleteValidatesOwnershipBeforeDeletingAnything() {
        MealPlan owned = new MealPlan();
        owned.setMealPlanId(10);
        when(plans.findByMealPlanIdAndUserUserId(10, 1)).thenReturn(Optional.of(owned));
        when(plans.findByMealPlanIdAndUserUserId(20, 1)).thenReturn(Optional.empty());

        assertThrows(
                ResponseStatusException.class,
                () -> service.removeBulk(1, List.of(10, 20)));

        verify(plans, never()).deleteAll(any());
    }
}
