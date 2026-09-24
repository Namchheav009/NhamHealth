package com.nhamhealth.nhamhealth_api.service.meal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.AiAutoFillPlanRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AiAutoFillPlanResponse;
import com.nhamhealth.nhamhealth_api.dto.response.MealPlanResponse;
import com.nhamhealth.nhamhealth_api.dto.response.WeightLossForecastResponse;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.entity.MealPlan;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;
import com.nhamhealth.nhamhealth_api.repository.catalog.FoodNutritionRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealPlanRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.WellnessProfileRepository;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService.AutoFillPlanSynthesis;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService.DaySlotSelection;

class MealPlannerForecastServiceTests {

        private MealPlanRepository mealPlanRepository;
        private WellnessProfileRepository wellnessProfileRepository;
        private UserProfileRepository userProfileRepository;
        private PlannerMealRepository plannerMealRepository;
        private FoodNutritionRepository foodNutritionRepository;
        private MealPlannerService mealPlannerService;
        private IbmMealPlannerRecommendationService ibmRecommendationService;
        private MealPlannerForecastService forecastService;

        @BeforeEach
        void setUp() {
                mealPlanRepository = mock(MealPlanRepository.class);
                wellnessProfileRepository = mock(WellnessProfileRepository.class);
                userProfileRepository = mock(UserProfileRepository.class);
                plannerMealRepository = mock(PlannerMealRepository.class);
                foodNutritionRepository = mock(FoodNutritionRepository.class);
                mealPlannerService = mock(MealPlannerService.class);
                ibmRecommendationService = mock(IbmMealPlannerRecommendationService.class);

                forecastService = new MealPlannerForecastService(
                                mealPlanRepository,
                                wellnessProfileRepository,
                                userProfileRepository,
                                plannerMealRepository,
                                foodNutritionRepository,
                                mealPlannerService,
                                ibmRecommendationService);
        }

        @Test
        void calculatesWeightLossForMaleProfileWithPlannedDeficit() {
                Integer userId = 101;
                LocalDate today = LocalDate.of(2026, 9, 21);

                WellnessProfile wp = new WellnessProfile();
                wp.setWeightKg(new BigDecimal("80.0"));
                wp.setHeightCm(new BigDecimal("175.0"));
                wp.setAgeCached((short) 30);
                wp.setActivityLevel("MODERATE");
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(wp));

                UserProfile up = new UserProfile();
                up.setGender("MALE");
                when(userProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(up));

                PlannerMeal meal = new PlannerMeal();
                meal.setCalories(new BigDecimal("2000"));
                meal.setProteinGrams(new BigDecimal("130"));

                MealPlan plan = new MealPlan();
                plan.setPlanDate(today);
                plan.setPlannerMeal(meal);
                plan.setServings(BigDecimal.ONE);
                when(mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(eq(userId),
                                eq(today), any()))
                                .thenReturn(List.of(plan));

                PlannerMeal recMeal = new PlannerMeal();
                recMeal.setPlannerMealId(1);
                recMeal.setNameEn("High Protein Chicken Bowl");
                recMeal.setCategoryEn("Lunch");
                recMeal.setCalories(new BigDecimal("450"));
                recMeal.setProteinGrams(new BigDecimal("38"));
                recMeal.setActive(true);
                when(plannerMealRepository.findAllByOrderByNameEnAsc()).thenReturn(List.of(recMeal));

                FoodNutrition greenTea = new FoodNutrition();
                greenTea.setName("Green Tea");
                greenTea.setCalories(new BigDecimal("2"));
                greenTea.setProtein(BigDecimal.ZERO);
                greenTea.setSugar(BigDecimal.ZERO);
                greenTea.setServingUnit("cup");
                greenTea.setActive(true);
                when(foodNutritionRepository.findAllByActiveTrue()).thenReturn(List.of(greenTea));

                WeightLossForecastResponse response = forecastService.calculateForecast(userId, 28, today, "en",
                                "LOSE_WEIGHT");

                assertNotNull(response);
                assertEquals(new BigDecimal("80.0"), response.currentWeightKg());
                assertEquals(30, response.age());
                assertEquals(new BigDecimal("175.0"), response.heightCm());
                assertEquals(new BigDecimal("26.1"), response.bmi());
                assertEquals(new BigDecimal("25.3"), response.projectedBmi());
                assertEquals(new BigDecimal("56.7"), response.healthyWeightMinKg());
                assertEquals(new BigDecimal("76.3"), response.healthyWeightMaxKg());
                assertEquals("OVERWEIGHT", response.bmiStatus());
                assertEquals("LOSE", response.recommendedWeightDirection());
                assertEquals("MODERATE", response.activityLevel());
                assertTrue(response.hasBiometricProfile());
                assertFalse(response.energyEstimateUsesDefaults());
                assertEquals(28, response.timeframeDays());
                assertEquals(new BigDecimal("1749"), response.bmrCalories());
                assertEquals(new BigDecimal("2711"), response.tdeeCalories());
                assertEquals(new BigDecimal("2000"), response.dailyPlannedCalories());
                assertEquals(new BigDecimal("711"), response.dailyDeficitCalories());
                assertEquals(new BigDecimal("2.58"), response.projectedWeightLossKg());
                assertEquals(new BigDecimal("0.65"), response.weeklyPaceKg());
                assertEquals("OPTIMAL", response.paceStatus());
                assertFalse(response.calorieWarning());
                assertTrue(response.hasPlannedMeals());

                assertEquals(1, response.recommendedFoods().size());
                assertEquals("High Protein Chicken Bowl", response.recommendedFoods().getFirst().name());
                assertTrue(response.recommendedFoods().getFirst().rationale().contains("Weight-loss match"));

                assertEquals(1, response.recommendedBeverages().size());
                assertEquals("Green Tea", response.recommendedBeverages().getFirst().name());
                assertTrue(response.recommendedBeverages().getFirst().rationale().contains("Calorie-aware choice"));
        }

        @Test
        void rejectsWeightLossForecastForUsersUnder18() {
                Integer userId = 106;
                WellnessProfile profile = new WellnessProfile();
                profile.setAgeCached((short) 17);
                profile.setHeightCm(new BigDecimal("170"));
                profile.setWeightKg(new BigDecimal("65"));
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(profile));

                ResponseStatusException error = assertThrows(
                                ResponseStatusException.class,
                                () -> forecastService.calculateForecast(
                                                userId, 28, LocalDate.of(2026, 9, 21), "en", "LOSE_WEIGHT"));

                assertEquals(400, error.getStatusCode().value());
        }

        @Test
        void recommendsWeightGainBelowGeneralAdultBmiRange() {
                Integer userId = 109;
                WellnessProfile profile = new WellnessProfile();
                profile.setAgeCached((short) 25);
                profile.setHeightCm(new BigDecimal("175"));
                profile.setWeightKg(new BigDecimal("52"));
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(profile));

                WeightLossForecastResponse response = forecastService.calculateForecast(
                                userId, 28, LocalDate.of(2026, 9, 21), "en", "LOSE_WEIGHT");

                assertEquals("GAIN", response.recommendedWeightDirection());
                assertEquals(new BigDecimal("0.00"), response.projectedWeightLossKg());
                assertEquals(response.currentWeightKg(), response.projectedEndWeightKg());
        }

        @Test
        void rejectsWeightLossAutoFillForUsersUnder18() {
                Integer userId = 107;
                WellnessProfile profile = new WellnessProfile();
                profile.setAgeCached((short) 16);
                profile.setHeightCm(new BigDecimal("165"));
                profile.setWeightKg(new BigDecimal("55"));
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(profile));

                AiAutoFillPlanRequest request = new AiAutoFillPlanRequest(
                                LocalDate.of(2026, 9, 21), 7, "LOSE_WEIGHT", 28, true, true);

                ResponseStatusException error = assertThrows(
                                ResponseStatusException.class,
                                () -> forecastService.generateAiAutoFillPlan(userId, request, "en"));

                assertEquals(400, error.getStatusCode().value());
        }

        @Test
        void rejectsWeightLossForecastWhenRequiredProfileDataIsMissing() {
                Integer userId = 108;
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.empty());
                when(userProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.empty());

                ResponseStatusException error = assertThrows(
                                ResponseStatusException.class,
                                () -> forecastService.calculateForecast(
                                                userId, 28, LocalDate.of(2026, 9, 21), "en", "LOSE_WEIGHT"));

                assertEquals(400, error.getStatusCode().value());
                assertTrue(error.getReason().contains("date of birth, height and weight"));
        }

        @Test
        void maintenanceGoalChangesForecastAndRecommendationRanking() {
                Integer userId = 105;
                LocalDate start = LocalDate.of(2026, 9, 21);
                WellnessProfile profile = new WellnessProfile();
                profile.setWeightKg(new BigDecimal("75"));
                profile.setHeightCm(new BigDecimal("170"));
                profile.setAgeCached((short) 28);
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(profile));
                when(mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(
                                eq(userId), eq(start), any())).thenReturn(List.of());

                PlannerMeal lean = new PlannerMeal();
                lean.setPlannerMealId(10);
                lean.setNameEn("Lean Protein Plate");
                lean.setCategoryEn("Lunch");
                lean.setCalories(new BigDecimal("320"));
                lean.setProteinGrams(new BigDecimal("40"));
                lean.setCarbsGrams(new BigDecimal("10"));
                lean.setFatGrams(new BigDecimal("5"));
                lean.setActive(true);

                PlannerMeal balanced = new PlannerMeal();
                balanced.setPlannerMealId(11);
                balanced.setNameEn("Balanced Grain Bowl");
                balanced.setCategoryEn("Lunch");
                balanced.setCalories(new BigDecimal("500"));
                balanced.setProteinGrams(new BigDecimal("25"));
                balanced.setCarbsGrams(new BigDecimal("55"));
                balanced.setFatGrams(new BigDecimal("15"));
                balanced.setActive(true);
                when(plannerMealRepository.findAllByOrderByNameEnAsc()).thenReturn(List.of(lean, balanced));

                FoodNutrition water = new FoodNutrition();
                water.setName("Water");
                water.setCalories(BigDecimal.ZERO);
                water.setSugar(BigDecimal.ZERO);
                FoodNutrition milkTea = new FoodNutrition();
                milkTea.setName("Unsweetened Milk Tea");
                milkTea.setCalories(new BigDecimal("60"));
                milkTea.setSugar(BigDecimal.ZERO);
                when(foodNutritionRepository.findAllByActiveTrue()).thenReturn(List.of(water, milkTea));

                WeightLossForecastResponse loss = forecastService.calculateForecast(
                                userId, 28, start, "en", "LOSE_WEIGHT");
                WeightLossForecastResponse maintain = forecastService.calculateForecast(
                                userId, 28, start, "en", "MAINTAIN_HEALTH");

                assertEquals("Lean Protein Plate", loss.recommendedFoods().getFirst().name());
                assertEquals("LOSE", loss.recommendedWeightDirection());
                assertEquals("Balanced Grain Bowl", maintain.recommendedFoods().getFirst().name());
                assertEquals("Water", loss.recommendedBeverages().getFirst().name());
                assertEquals("Unsweetened Milk Tea", maintain.recommendedBeverages().getFirst().name());
                assertTrue(loss.recommendedBeverages().getFirst().rationale().contains("Calorie-aware choice"));
                assertTrue(maintain.recommendedBeverages().getFirst().rationale().contains("Maintenance balance"));
                assertTrue(loss.dailyDeficitCalories().doubleValue() > 0);
                assertEquals(new BigDecimal("0"), maintain.dailyDeficitCalories());
                assertEquals(new BigDecimal("0.00"), maintain.projectedWeightLossKg());
                assertEquals("BALANCED", maintain.paceStatus());
                assertEquals("LOSE", maintain.recommendedWeightDirection());
                assertFalse(maintain.hasPlannedMeals());
                assertEquals("MODERATE_ESTIMATE", maintain.activityLevel());
                assertTrue(maintain.energyEstimateUsesDefaults());
                assertTrue(loss.aiAnalysisSummary().contains("preview"));
                assertTrue(maintain.aiAnalysisSummary().contains("preview"));
                assertTrue(maintain.recommendedFoods().getFirst().rationale().contains("Maintenance match"));
                assertFalse(maintain.aiAnalysisSummary().contains("fat loss"));
        }

        @Test
        void skippedMealsDoNotUnlockWeightEstimate() {
                Integer userId = 106;
                LocalDate start = LocalDate.of(2026, 9, 21);
                WellnessProfile profile = new WellnessProfile();
                profile.setWeightKg(new BigDecimal("70"));
                profile.setHeightCm(new BigDecimal("170"));
                profile.setAgeCached((short) 28);
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(profile));
                MealPlan skipped = new MealPlan();
                skipped.setPlanDate(start);
                skipped.setStatus("SKIPPED");
                PlannerMeal meal = new PlannerMeal();
                meal.setCalories(new BigDecimal("400"));
                skipped.setPlannerMeal(meal);
                when(mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(
                                eq(userId), eq(start), any())).thenReturn(List.of(skipped));

                WeightLossForecastResponse response = forecastService.calculateForecast(
                                userId, 28, start, "en", "LOSE_WEIGHT");

                assertFalse(response.hasPlannedMeals());
                assertTrue(response.aiAnalysisSummary().contains("preview"));
        }

        @Test
        void warnsOnExtremeCalorieRestrictionBelowSafeFloor() {
                Integer userId = 102;
                LocalDate today = LocalDate.of(2026, 9, 21);

                WellnessProfile wp = new WellnessProfile();
                wp.setWeightKg(new BigDecimal("60.0"));
                wp.setHeightCm(new BigDecimal("160.0"));
                wp.setAgeCached((short) 25);
                wp.setActivityLevel("LIGHT");
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(wp));

                UserProfile up = new UserProfile();
                up.setGender("FEMALE");
                when(userProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(up));

                PlannerMeal lowMeal = new PlannerMeal();
                lowMeal.setCalories(new BigDecimal("950"));
                lowMeal.setProteinGrams(new BigDecimal("40"));

                MealPlan plan = new MealPlan();
                plan.setPlanDate(today);
                plan.setPlannerMeal(lowMeal);
                plan.setServings(BigDecimal.ONE);
                when(mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(eq(userId),
                                eq(today), any()))
                                .thenReturn(List.of(plan));

                WeightLossForecastResponse response = forecastService.calculateForecast(userId, 14, today, "km",
                                "LOSE_WEIGHT");

                assertNotNull(response);
                assertTrue(response.calorieWarning());
                assertTrue(response.calorieWarningMessage().contains("1200"));
                assertEquals("MAINTAIN", response.recommendedWeightDirection());
                assertTrue(response.aiAnalysisSummary().contains("រក្សា"));
        }

        @Test
        void handlesZeroOrSurplusDeficitGracefully() {
                Integer userId = 103;
                LocalDate today = LocalDate.of(2026, 9, 21);

                WellnessProfile wp = new WellnessProfile();
                wp.setWeightKg(new BigDecimal("80.0"));
                wp.setHeightCm(new BigDecimal("170.0"));
                wp.setAgeCached((short) 35);
                wp.setActivityLevel("SEDENTARY");
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(wp));

                UserProfile up = new UserProfile();
                up.setGender("MALE");
                when(userProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(up));

                PlannerMeal highMeal = new PlannerMeal();
                highMeal.setCalories(new BigDecimal("3000"));
                highMeal.setProteinGrams(new BigDecimal("100"));

                MealPlan plan = new MealPlan();
                plan.setPlanDate(today);
                plan.setPlannerMeal(highMeal);
                plan.setServings(BigDecimal.ONE);
                when(mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(eq(userId),
                                eq(today), any()))
                                .thenReturn(List.of(plan));

                WeightLossForecastResponse response = forecastService.calculateForecast(userId, 28, today, "en",
                                "LOSE_WEIGHT");

                assertNotNull(response);
                assertEquals("SURPLUS", response.paceStatus());
                assertEquals(new BigDecimal("0.00"), response.projectedWeightLossKg());
                assertTrue(response.dailyDeficitCalories().doubleValue() < 0);
        }

        @Test
        void generatesAiAutoFillPlanWithDeficitAndPersistsMeals() {
                Integer userId = 104;
                LocalDate start = LocalDate.of(2026, 9, 21);

                WellnessProfile wp = new WellnessProfile();
                wp.setWeightKg(new BigDecimal("75.0"));
                wp.setHeightCm(new BigDecimal("175.0"));
                wp.setAgeCached((short) 28);
                wp.setActivityLevel("MODERATE");
                when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(wp));

                UserProfile up = new UserProfile();
                up.setGender("MALE");
                when(userProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(up));

                PlannerMeal meal1 = new PlannerMeal();
                meal1.setPlannerMealId(10);
                meal1.setNameEn("Quinoa Chicken Salad");
                meal1.setCategoryEn("Healthy Lunch");
                meal1.setCalories(new BigDecimal("450"));
                meal1.setProteinGrams(new BigDecimal("35"));
                meal1.setActive(true);

                when(plannerMealRepository.findAllByOrderByNameEnAsc()).thenReturn(List.of(meal1));
                when(mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(eq(userId),
                                eq(start), any()))
                                .thenReturn(List.of());

                AutoFillPlanSynthesis synthesis = new AutoFillPlanSynthesis(
                                List.of(new DaySlotSelection(start, "LUNCH", meal1, "Optimized for Lunch")),
                                "IBM Granite balanced your weekly deficit.",
                                1950.0,
                                520.0,
                                0.47,
                                "ibm/granite-3-3-8b-instruct");

                when(ibmRecommendationService.synthesizeClinicalPlan(any(), any(), any(), any(Double.class),
                                any(Double.class), eq("LOSE_WEIGHT"), eq("en")))
                                .thenReturn(synthesis);

                MealPlanResponse mockCreated = new MealPlanResponse(
                                501, start, "LUNCH", BigDecimal.ONE, "PLANNED", null, null,
                                10, "Quinoa Chicken Salad", 2, "Healthy Lunch", "https://img.jpg",
                                new BigDecimal("450"), new BigDecimal("35"), new BigDecimal("30"), new BigDecimal("10"),
                                "Desc", 20, "EASY", List.of(), List.of(), List.of());
                when(mealPlannerService.addOrReplace(eq(userId), any(), eq("en"))).thenReturn(mockCreated);

                AiAutoFillPlanRequest request = new AiAutoFillPlanRequest(start, 7, "LOSE_WEIGHT", 28, true, true);

                AiAutoFillPlanResponse response = forecastService.generateAiAutoFillPlan(userId, request, "en");

                assertNotNull(response);
                assertEquals(1, response.filledCount());
                assertEquals(1950.0, response.dailyPlannedCalories());
                assertEquals(520.0, response.dailyDeficit());
                assertTrue(response.totalProjectedLossKg() > 1.5);
                assertEquals("LOSE_WEIGHT", response.goal());
                assertNotNull(response.aiRationale());
        }

        @Test
        void rejectsWeightLossAutoFillDuringPregnancyOrBreastfeeding() {
                AiAutoFillPlanRequest request = new AiAutoFillPlanRequest(
                                LocalDate.of(2026, 9, 21),
                                7,
                                "LOSE_WEIGHT",
                                28,
                                true,
                                true,
                                "BALANCED",
                                List.of(),
                                List.of(),
                                List.of("PREGNANT_OR_BREASTFEEDING"));

                ResponseStatusException error = assertThrows(
                                ResponseStatusException.class,
                                () -> forecastService.generateAiAutoFillPlan(104, request, "en"));

                assertEquals(400, error.getStatusCode().value());
        }

        @Test
        @SuppressWarnings({ "unchecked", "rawtypes" })
        void fillEmptyModeRepairsExistingDuplicateMealSlots() {
                Integer userId = 105;
                LocalDate start = LocalDate.of(2026, 9, 21);
                PlannerMeal repeated = plannerMeal(10, "Repeated meal");
                List<MealPlan> existingPlans = List.of(
                                planned(start, "BREAKFAST", repeated),
                                planned(start, "LUNCH", repeated),
                                planned(start, "DINNER", repeated),
                                planned(start, "SNACK", repeated));
                when(mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(
                                eq(userId), eq(start), any())).thenReturn(existingPlans);
                when(plannerMealRepository.findAllByOrderByNameEnAsc()).thenReturn(List.of(
                                repeated,
                                plannerMeal(11, "Fresh lunch"),
                                plannerMeal(12, "Fresh dinner"),
                                plannerMeal(13, "Fresh snack")));

                ArgumentCaptor<Map<LocalDate, List<String>>> slotsCaptor = ArgumentCaptor.forClass(Map.class);
                when(ibmRecommendationService.synthesizeClinicalPlan(
                                any(), slotsCaptor.capture(), any(), any(Double.class), any(Double.class),
                                any(), any(), any()))
                                .thenReturn(new AutoFillPlanSynthesis(
                                                List.of(), "Duplicates repaired", 0, 0, 0,
                                                "clinical-rule-fallback"));

                forecastService.generateAiAutoFillPlan(
                                userId,
                                new AiAutoFillPlanRequest(start, 1, "MAINTAIN_HEALTH", 28, true, true),
                                "en");

                assertEquals(
                                List.of("LUNCH", "DINNER", "SNACK"),
                                slotsCaptor.getValue().get(start));
        }

        private static PlannerMeal plannerMeal(int id, String name) {
                PlannerMeal meal = new PlannerMeal();
                meal.setPlannerMealId(id);
                meal.setNameEn(name);
                meal.setCategoryEn("Healthy meal");
                meal.setCalories(new BigDecimal("400"));
                meal.setProteinGrams(new BigDecimal("25"));
                meal.setCarbsGrams(new BigDecimal("40"));
                meal.setFatGrams(new BigDecimal("12"));
                meal.setActive(true);
                return meal;
        }

        private static MealPlan planned(LocalDate date, String slot, PlannerMeal meal) {
                MealPlan plan = new MealPlan();
                plan.setPlanDate(date);
                plan.setMealType(slot);
                plan.setPlannerMeal(meal);
                plan.setServings(BigDecimal.ONE);
                return plan;
        }
}
