package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Set;

import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.AiAutoFillPlanRequest;
import com.nhamhealth.nhamhealth_api.dto.request.MealRecommendationRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AiAutoFillPlanResponse;
import com.nhamhealth.nhamhealth_api.dto.response.MealPlannerAiRecommendationResponse;
import com.nhamhealth.nhamhealth_api.dto.response.WeeklyMealRecommendationResponse;
import com.nhamhealth.nhamhealth_api.dto.response.WeightLossForecastResponse;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;
import com.nhamhealth.nhamhealth_api.service.meal.MealPlannerForecastService;

class WeeklyMealPlannerApiControllerTests {

        @Test
        void returnsLocalizedActiveAdminPlannerMeals() {
                WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
                PlannerMeal meal = new PlannerMeal();
                meal.setPlannerMealId(42);
                meal.setNameEn("Grilled fish");
                meal.setNameKm("ត្រីអាំង");
                meal.setCategoryEn("Dinner");
                MealCategory category = new MealCategory();
                category.setCategoryId(7);
                meal.setCategory(category);
                meal.setCalories(new BigDecimal("510"));
                meal.setProteinGrams(new BigDecimal("38"));
                meal.setCarbsGrams(BigDecimal.ZERO);
                meal.setFatGrams(BigDecimal.ZERO);
                meal.setIngredientsText("Fish | 1 | piece | ត្រី");
                WeeklyMealRecommendation recommendation = new WeeklyMealRecommendation();
                recommendation.setPlannerMeal(meal);
                recommendation.setDayOfWeek("FRIDAY");
                recommendation.setMealSlot("DINNER");
                recommendation.setSortOrder(1);
                recommendation.setNote("High protein choice");
                when(repository.findAllByActiveTrueAndPlannerMealActiveTrueOrderBySortOrderAscRecommendationIdAsc())
                                .thenReturn(List.of(recommendation));

                var response = new WeeklyMealPlannerApiController(repository).recommendations(null, null, "km");
                assertEquals(1, response.getBody().size());
                assertEquals(42, response.getBody().getFirst().plannerMealId());
                assertEquals("ត្រីអាំង", response.getBody().getFirst().mealName());
                assertEquals("ត្រី", response.getBody().getFirst().ingredients().getFirst().name());
                assertEquals(BigDecimal.ONE, response.getBody().getFirst().ingredients().getFirst().quantity());
                assertEquals("FRIDAY", response.getBody().getFirst().dayOfWeek());
                assertEquals("DINNER", response.getBody().getFirst().mealSlot());
        }

        @Test
        void filtersRecommendationsByDayOfWeek() {
                WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
                PlannerMeal meal = new PlannerMeal();
                meal.setPlannerMealId(99);
                meal.setNameEn("Chicken Salad");
                meal.setNameKm("ញាំមាន់");
                MealCategory category = new MealCategory();
                category.setCategoryId(3);
                meal.setCategory(category);
                meal.setCalories(new BigDecimal("350"));
                meal.setProteinGrams(new BigDecimal("30"));
                meal.setCarbsGrams(BigDecimal.ZERO);
                meal.setFatGrams(BigDecimal.ZERO);
                WeeklyMealRecommendation recommendation = new WeeklyMealRecommendation();
                recommendation.setPlannerMeal(meal);
                recommendation.setDayOfWeek("MONDAY");
                recommendation.setMealSlot("LUNCH");
                recommendation.setSortOrder(1);

                when(repository
                                .findAllByActiveTrueAndPlannerMealActiveTrueAndDayOfWeekInOrderBySortOrderAscRecommendationIdAsc(
                                                List.of("ALL", "MONDAY")))
                                .thenReturn(List.of(recommendation));

                var response = new WeeklyMealPlannerApiController(repository).recommendations("MONDAY", null, "en");
                assertEquals(1, response.getBody().size());
                assertEquals(99, response.getBody().getFirst().plannerMealId());
                assertEquals("Chicken Salad", response.getBody().getFirst().mealName());
        }

        @Test
        void filtersRecommendationsByUserWeightGoal() {
                WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
                PlannerMeal loseWeightMeal = plannerMeal(201, "Light chicken salad", Set.of("LOSE_WEIGHT"));
                PlannerMeal gainWeightMeal = plannerMeal(202, "High calorie rice bowl", Set.of("GAIN_WEIGHT"));

                WeeklyMealRecommendation loseWeightRecommendation = new WeeklyMealRecommendation();
                loseWeightRecommendation.setPlannerMeal(loseWeightMeal);
                loseWeightRecommendation.setDayOfWeek("ALL");
                loseWeightRecommendation.setMealSlot("LUNCH");
                WeeklyMealRecommendation gainWeightRecommendation = new WeeklyMealRecommendation();
                gainWeightRecommendation.setPlannerMeal(gainWeightMeal);
                gainWeightRecommendation.setDayOfWeek("ALL");
                gainWeightRecommendation.setMealSlot("LUNCH");

                when(repository.findAllByActiveTrueAndPlannerMealActiveTrueOrderBySortOrderAscRecommendationIdAsc())
                                .thenReturn(List.of(loseWeightRecommendation, gainWeightRecommendation));

                var response = new WeeklyMealPlannerApiController(repository)
                                .recommendations(null, null, null, "en", "LOSE_WEIGHT");

                assertEquals(1, response.getBody().size());
                assertEquals(201, response.getBody().getFirst().plannerMealId());
        }

        private static PlannerMeal plannerMeal(int id, String name, Set<String> goals) {
                PlannerMeal meal = new PlannerMeal();
                meal.setPlannerMealId(id);
                meal.setNameEn(name);
                meal.setCategoryEn("Lunch");
                meal.setCalories(new BigDecimal("400"));
                meal.setProteinGrams(new BigDecimal("25"));
                meal.setCarbsGrams(new BigDecimal("40"));
                meal.setFatGrams(new BigDecimal("12"));
                meal.setWeightGoals(goals);
                return meal;
        }

        @Test
        void recommendationWithoutPrimaryCategoryDoesNotCrash() {
                WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
                PlannerMeal meal = new PlannerMeal();
                meal.setPlannerMealId(100);
                meal.setNameEn("Uncategorized meal");
                meal.setCategoryEn("Other");
                meal.setCalories(new BigDecimal("300"));
                meal.setProteinGrams(BigDecimal.ZERO);
                meal.setCarbsGrams(BigDecimal.ZERO);
                meal.setFatGrams(BigDecimal.ZERO);

                WeeklyMealRecommendation recommendation = new WeeklyMealRecommendation();
                recommendation.setPlannerMeal(meal);
                recommendation.setDayOfWeek("ALL");
                recommendation.setMealSlot("SNACK");
                when(repository.findAllByActiveTrueAndPlannerMealActiveTrueOrderBySortOrderAscRecommendationIdAsc())
                                .thenReturn(List.of(recommendation));

                var response = new WeeklyMealPlannerApiController(repository).recommendations(null, null, "en");

                assertEquals(1, response.getBody().size());
                assertEquals(null, response.getBody().getFirst().categoryId());
        }

        @Test
        void returnsDedicatedKhmerIngredientsInstructionsAndTagsWhenAvailable() {
                WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
                PlannerMeal meal = new PlannerMeal();
                meal.setPlannerMealId(55);
                meal.setNameEn("Steamed Chicken Rice");
                meal.setNameKm("បាយមាន់ស្ងោរ");
                meal.setCategoryEn("Lunch");
                MealCategory category = new MealCategory();
                category.setCategoryId(2);
                meal.setCategory(category);
                meal.setCalories(new BigDecimal("480"));
                meal.setProteinGrams(new BigDecimal("35"));
                meal.setCarbsGrams(new BigDecimal("50"));
                meal.setFatGrams(new BigDecimal("12"));
                meal.setIngredientsText("Chicken | 150 | g\nRice | 100 | g");
                meal.setIngredientsTextKm("សាច់មាន់ | 150 | g\nបាយ | 100 | g");
                meal.setInstructionsText("Step 1: Boil chicken.\nStep 2: Cook rice.");
                meal.setInstructionsTextKm("ជំហានទី ១៖ ស្ងោរសាច់មាន់។\nជំហានទី ២៖ ដាំបាយ។");
                meal.setTagsText("High Protein, Balanced");
                meal.setTagsTextKm("ប្រូតេអ៊ីនខ្ពស់, មានតុល្យភាព");

                WeeklyMealRecommendation recommendation = new WeeklyMealRecommendation();
                recommendation.setPlannerMeal(meal);
                recommendation.setDayOfWeek("ALL");
                recommendation.setMealSlot("LUNCH");
                recommendation.setSortOrder(1);

                when(repository.findAllByActiveTrueAndPlannerMealActiveTrueOrderBySortOrderAscRecommendationIdAsc())
                                .thenReturn(List.of(recommendation));

                // When requesting Khmer
                var kmResponse = new WeeklyMealPlannerApiController(repository).recommendations(null, null, "km");
                var kmItem = kmResponse.getBody().getFirst();
                assertEquals("បាយមាន់ស្ងោរ", kmItem.mealName());
                assertEquals(List.of("សាច់មាន់", "បាយ"), kmItem.ingredients().stream().map(i -> i.name()).toList());
                assertEquals(List.of("ជំហានទី ១៖ ស្ងោរសាច់មាន់។", "ជំហានទី ២៖ ដាំបាយ។"), kmItem.instructions());
                assertEquals(List.of("ប្រូតេអ៊ីនខ្ពស់", "មានតុល្យភាព"), kmItem.tags());

                // When requesting English
                var enResponse = new WeeklyMealPlannerApiController(repository).recommendations(null, null, "en");
                var enItem = enResponse.getBody().getFirst();
                assertEquals("Steamed Chicken Rice", enItem.mealName());
                assertEquals(List.of("Chicken", "Rice"), enItem.ingredients().stream().map(i -> i.name()).toList());
                assertEquals(List.of("Step 1: Boil chicken.", "Step 2: Cook rice."), enItem.instructions());
                assertEquals(List.of("High Protein", "Balanced"), enItem.tags());
        }

        @Test
        void delegatesToForecastService() {
                WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
                MealPlannerForecastService forecastService = mock(MealPlannerForecastService.class);

                WeightLossForecastResponse mockForecast = new WeightLossForecastResponse(
                                new BigDecimal("75.0"), 28, new BigDecimal("175.0"), new BigDecimal("24.5"),
                                new BigDecimal("23.7"), new BigDecimal("56.7"), new BigDecimal("76.3"),
                                "HEALTHY", "MAINTAIN", "LOSE_WEIGHT", "MODERATE", true, false,
                                new BigDecimal("72.0"), new BigDecimal("2.50"),
                                new BigDecimal("72.5"), new BigDecimal("1650"), new BigDecimal("2400"),
                                new BigDecimal("1800"), new BigDecimal("600"), 28, new BigDecimal("0.55"),
                                "OPTIMAL", "Healthy pace", false, "", List.of(), List.of(), "Good progress", true);

                when(forecastService.calculateForecast(null, 28, null, "en", "LOSE_WEIGHT"))
                                .thenReturn(mockForecast);

                var controller = new WeeklyMealPlannerApiController(repository, null, forecastService);
                var response = controller.forecast(null, 28, null, "en", "LOSE_WEIGHT");

                assertNotNull(response.getBody());
                assertEquals(new BigDecimal("75.0"), response.getBody().currentWeightKg());
                assertEquals(new BigDecimal("2.50"), response.getBody().projectedWeightLossKg());
                assertEquals("OPTIMAL", response.getBody().paceStatus());
        }

        @Test
        void forecastErrorsExposeTheActionableServiceReason() {
                var handler = new WeeklyMealPlannerApiExceptionHandler();
                var response = handler.handle(new ResponseStatusException(
                                HttpStatus.BAD_REQUEST,
                                "Complete your date of birth, height and weight before using a weight-loss plan."));

                assertEquals(400, response.getStatusCode().value());
                assertEquals(
                                "Complete your date of birth, height and weight before using a weight-loss plan.",
                                response.getBody().get("message"));
        }

        @Test
        void delegatesToAiAutoFillService() {
                WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
                MealPlannerForecastService forecastService = mock(MealPlannerForecastService.class);

                AiAutoFillPlanRequest request = new AiAutoFillPlanRequest(
                                LocalDate.of(2026, 9, 21), 7, "LOSE_WEIGHT", 28, true, true);

                AiAutoFillPlanResponse mockResponse = new AiAutoFillPlanResponse(
                                List.of(), 5, 1900.0, 500.0, 2400.0, 1600.0, 0.45, 28, 1.82,
                                "IBM Granite auto-filled plan", "LOSE_WEIGHT", "ibm/granite-3-3-8b-instruct");

                when(forecastService.generateAiAutoFillPlan(null, request, "en")).thenReturn(mockResponse);

                var controller = new WeeklyMealPlannerApiController(repository, null, forecastService);
                var response = controller.aiAutoFill(null, request, "en");

                assertNotNull(response.getBody());
                assertEquals(5, response.getBody().filledCount());
                assertEquals(1900.0, response.getBody().dailyPlannedCalories());
                assertEquals(500.0, response.getBody().dailyDeficit());
                assertEquals("LOSE_WEIGHT", response.getBody().goal());
        }

        @Test
        void delegatesToMealRecommendationService() {
                WeeklyMealRecommendationRepository repository = mock(WeeklyMealRecommendationRepository.class);
                MealPlannerForecastService forecastService = mock(MealPlannerForecastService.class);

                MealRecommendationRequest request = new MealRecommendationRequest(
                                LocalDate.of(2026, 9, 23), "BREAKFAST", "LOSE_WEIGHT", null, "ADD");

                WeeklyMealRecommendationResponse meal = new WeeklyMealRecommendationResponse(
                                null, "ALL", "BREAKFAST", 15, "Steamed egg", "https://img.jpg",
                                new BigDecimal("250"), new BigDecimal("18"), new BigDecimal("5"), new BigDecimal("12"),
                                1, "Breakfast", "Desc", 15, "EASY", List.of(), List.of(), List.of(), "", 0, List.of());

                MealPlannerAiRecommendationResponse mockResponse = new MealPlannerAiRecommendationResponse(
                                meal, List.of(), "High protein breakfast recommendation", "ADD",
                                "Google Gemini / gemini-3.5-flash-lite");

                when(forecastService.recommendMeal(null, request, "en")).thenReturn(mockResponse);

                var controller = new WeeklyMealPlannerApiController(repository, null, forecastService);
                var response = controller.recommendMeal(null, request, "en");

                assertNotNull(response.getBody());
                assertEquals(15, response.getBody().recommendedMeal().plannerMealId());
                assertEquals("ADD", response.getBody().actionType());
                assertEquals("High protein breakfast recommendation", response.getBody().aiRationale());
        }
}
