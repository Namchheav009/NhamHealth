package com.nhamhealth.nhamhealth_api.service.meal;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.Period;
import java.text.Normalizer;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Optional;
import java.util.Set;
import java.util.stream.Collectors;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.AiAutoFillPlanRequest;
import com.nhamhealth.nhamhealth_api.dto.request.MealPlanRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AiAutoFillPlanResponse;
import com.nhamhealth.nhamhealth_api.dto.response.ForecastRecommendationItem;
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
import com.nhamhealth.nhamhealth_api.service.ai.GeminiMealPlannerAutoFillService;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService.AutoFillPlanSynthesis;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService.DaySlotSelection;

@Service
public class MealPlannerForecastService {
    private static final Logger log = LoggerFactory.getLogger(MealPlannerForecastService.class);

    // Clinical benchmark: ~7,700 kcal deficit ≈ 1 kg of fat loss
    private static final double KCAL_PER_KG_FAT = 7700.0;
    private static final double MIN_CALORIES_FEMALE = 1200.0;
    private static final double MIN_CALORIES_MALE = 1500.0;

    private final MealPlanRepository mealPlanRepository;
    private final WellnessProfileRepository wellnessProfileRepository;
    private final UserProfileRepository userProfileRepository;
    private final PlannerMealRepository plannerMealRepository;
    private final FoodNutritionRepository foodNutritionRepository;
    private final MealPlannerService mealPlannerService;
    private final IbmMealPlannerRecommendationService ibmRecommendationService;
    private final GeminiMealPlannerAutoFillService geminiAutoFillService;

    @Autowired
    public MealPlannerForecastService(
            MealPlanRepository mealPlanRepository,
            WellnessProfileRepository wellnessProfileRepository,
            UserProfileRepository userProfileRepository,
            PlannerMealRepository plannerMealRepository,
            FoodNutritionRepository foodNutritionRepository,
            MealPlannerService mealPlannerService,
            IbmMealPlannerRecommendationService ibmRecommendationService,
            GeminiMealPlannerAutoFillService geminiAutoFillService) {
        this.mealPlanRepository = mealPlanRepository;
        this.wellnessProfileRepository = wellnessProfileRepository;
        this.userProfileRepository = userProfileRepository;
        this.plannerMealRepository = plannerMealRepository;
        this.foodNutritionRepository = foodNutritionRepository;
        this.mealPlannerService = mealPlannerService;
        this.ibmRecommendationService = ibmRecommendationService;
        this.geminiAutoFillService = geminiAutoFillService;
    }

    public MealPlannerForecastService(
            MealPlanRepository mealPlanRepository,
            WellnessProfileRepository wellnessProfileRepository,
            UserProfileRepository userProfileRepository,
            PlannerMealRepository plannerMealRepository,
            FoodNutritionRepository foodNutritionRepository,
            MealPlannerService mealPlannerService,
            IbmMealPlannerRecommendationService ibmRecommendationService) {
        this(mealPlanRepository, wellnessProfileRepository, userProfileRepository,
                plannerMealRepository, foodNutritionRepository, mealPlannerService,
                ibmRecommendationService, null);
    }

    @Transactional(readOnly = true)
    public WeightLossForecastResponse calculateForecast(
            Integer userId,
            Integer requestedDays,
            LocalDate startDate,
            String requestedLang,
            String requestedGoal) {

        final int timeframeDays = (requestedDays == null || requestedDays <= 0) ? 28 : Math.min(requestedDays, 90);
        final LocalDate start = startDate != null ? startDate : LocalDate.now();
        final String lang = (requestedLang != null && requestedLang.equalsIgnoreCase("km")) ? "km" : "en";
        final boolean isKhmer = "km".equals(lang);
        final String goal = IbmMealPlannerRecommendationService.normalizeGoal(requestedGoal);
        final boolean isWeightLoss = "LOSE_WEIGHT".equals(goal);

        // 1. Resolve User Biometrics
        Optional<WellnessProfile> wellnessOpt = userId != null ? wellnessProfileRepository.findByUser_UserId(userId)
                : Optional.empty();
        Optional<UserProfile> profileOpt = userId != null ? userProfileRepository.findByUser_UserId(userId)
                : Optional.empty();

        double weightKg = 70.0;
        double heightCm = 170.0;
        int age = 28;
        String activityLevel = "MODERATE";
        String gender = "MALE";

        if (wellnessOpt.isPresent()) {
            WellnessProfile wp = wellnessOpt.get();
            if (wp.getWeightKg() != null && wp.getWeightKg().doubleValue() > 0) {
                weightKg = wp.getWeightKg().doubleValue();
            }
            if (wp.getHeightCm() != null && wp.getHeightCm().doubleValue() > 0) {
                heightCm = wp.getHeightCm().doubleValue();
            }
            if (wp.getAgeCached() != null && wp.getAgeCached() > 0) {
                age = wp.getAgeCached().intValue();
            }
            if (wp.getActivityLevel() != null && !wp.getActivityLevel().isBlank()) {
                activityLevel = wp.getActivityLevel().trim().toUpperCase(Locale.ROOT);
            }
        }

        if (profileOpt.isPresent()) {
            UserProfile up = profileOpt.get();
            if (up.getGender() != null && !up.getGender().isBlank()) {
                gender = up.getGender().trim().toUpperCase(Locale.ROOT);
            }
            if (up.getDateOfBirth() != null && (wellnessOpt.isEmpty() || wellnessOpt.get().getAgeCached() == null)) {
                age = Math.max(12, Period.between(up.getDateOfBirth(), LocalDate.now()).getYears());
            }
        }

        boolean isFemale = gender.contains("FEMALE") || gender.contains("WOMAN") || gender.equalsIgnoreCase("F");

        // 2. Compute Mifflin-St Jeor BMR
        // Men: 10 * weight(kg) + 6.25 * height(cm) - 5 * age + 5
        // Women: 10 * weight(kg) + 6.25 * height(cm) - 5 * age - 161
        double bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + (isFemale ? -161.0 : 5.0);
        bmr = Math.max(800.0, bmr);

        // 3. Activity Multiplier & TDEE
        double activityMultiplier = switch (activityLevel) {
            case "SEDENTARY" -> 1.2;
            case "LIGHT", "LIGHTLY_ACTIVE" -> 1.375;
            case "MODERATE", "MODERATELY_ACTIVE" -> 1.55;
            case "ACTIVE", "VERY_ACTIVE" -> 1.725;
            case "EXTRA_ACTIVE", "EXTREMELY_ACTIVE" -> 1.9;
            default -> 1.55;
        };
        double tdee = bmr * activityMultiplier;

        // 4. Planned Meals & Daily Calorie Intake
        double dailyPlannedCalories;
        List<MealPlan> plannedMeals = (userId != null)
                ? mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(userId, start,
                        start.plusDays(timeframeDays - 1L)).stream()
                        .filter(plan -> !"SKIPPED".equalsIgnoreCase(plan.getStatus()))
                        .toList()
                : List.of();

        if (!plannedMeals.isEmpty()) {
            Set<LocalDate> plannedDates = plannedMeals.stream().map(MealPlan::getPlanDate).collect(Collectors.toSet());
            double totalCalories = 0.0;
            for (MealPlan plan : plannedMeals) {
                if (plan.getPlannerMeal() != null && plan.getPlannerMeal().getCalories() != null) {
                    double mealCal = plan.getPlannerMeal().getCalories().doubleValue();
                    double servings = plan.getServings() != null ? plan.getServings().doubleValue() : 1.0;
                    totalCalories += (mealCal * servings);
                }
            }
            int effectiveDays = Math.max(1, plannedDates.size());
            dailyPlannedCalories = totalCalories / effectiveDays;
        } else {
            // Preview the correct calorie target before the user has planned meals.
            dailyPlannedCalories = isWeightLoss
                    ? Math.max(isFemale ? MIN_CALORIES_FEMALE : MIN_CALORIES_MALE, tdee - 500.0)
                    : tdee;
        }

        // 5. Goal-aware energy and projection metrics
        double dailyDeficit = tdee - dailyPlannedCalories;
        double weeklyPaceKg = isWeightLoss ? (dailyDeficit * 7.0) / KCAL_PER_KG_FAT : 0.0;
        double projectedWeightLossKg = isWeightLoss && dailyDeficit > 0
                ? (dailyDeficit * timeframeDays) / KCAL_PER_KG_FAT
                : 0.0;
        double projectedEndWeightKg = Math.max(30.0, weightKg - projectedWeightLossKg);

        // 6. Goal-aware status and description
        String paceStatus;
        String paceDescription;
        if (!isWeightLoss && Math.abs(dailyDeficit) <= 200.0) {
            paceStatus = "BALANCED";
            paceDescription = isKhmer
                    ? "ផែនការរបស់អ្នកស្ថិតជិតតម្រូវការថាមពលប្រចាំថ្ងៃ ដែលសមស្របសម្រាប់រក្សាទម្ងន់ និងថាមពលឱ្យថេរ។"
                    : "Planned meals are close to estimated daily energy needs. Include every meal for a useful comparison.";
        } else if (!isWeightLoss && dailyDeficit > 200.0) {
            paceStatus = "BELOW_TARGET";
            paceDescription = isKhmer
                    ? "ផែនការរបស់អ្នកទាបជាងតម្រូវការថាមពលសម្រាប់ការរក្សាទម្ងន់។ បន្ថែមអាហារមានតុល្យភាព ឬចំណែកសមស្រប។"
                    : "Planned meals are below estimated maintenance needs. Check for missing meals before adjusting portions.";
        } else if (!isWeightLoss) {
            paceStatus = "ABOVE_TARGET";
            paceDescription = isKhmer
                    ? "ផែនការរបស់អ្នកខ្ពស់ជាងតម្រូវការថាមពលសម្រាប់ការរក្សាទម្ងន់។ ពិនិត្យទំហំចំណែក និងអាហារបន្ថែម។"
                    : "Planned meals are above estimated maintenance needs. Review portions and calorie-dense extras.";
        } else if (dailyDeficit <= 0) {
            paceStatus = "SURPLUS";
            paceDescription = isKhmer
                    ? "កាឡូរីគ្រោងទុកលើសពីការដុតរំលាយប្រចាំថ្ងៃ។ កាត់បន្ថយទំហំអាហារដើម្បីចាប់ផ្តើមសម្រកទម្ងន់។"
                    : "Planned intake exceeds your daily expenditure. Reduce portion sizes or select lighter meals to induce fat loss.";
        } else if (weeklyPaceKg < 0.4) {
            paceStatus = "STEADY";
            paceDescription = isKhmer
                    ? String.format("ការប៉ាន់ស្មានតាមផែនការ %.2f គ.ក្រ/សប្តាហ៍។ លទ្ធផលពិតអាចខុសគ្នា។",
                            weeklyPaceKg)
                    : String.format("Planning estimate: %.2f kg/week. Actual results may differ.",
                            weeklyPaceKg);
        } else if (weeklyPaceKg <= 1.0) {
            paceStatus = "OPTIMAL";
            paceDescription = isKhmer
                    ? String.format("ការប៉ាន់ស្មានតាមផែនការ %.2f គ.ក្រ/សប្តាហ៍។ លទ្ធផលពិតអាចខុសគ្នា។",
                            weeklyPaceKg)
                    : String.format("Planning estimate: %.2f kg/week. Actual results may differ.",
                            weeklyPaceKg);
        } else {
            paceStatus = "RAPID";
            paceDescription = isKhmer
                    ? String.format(
                            "ការប៉ាន់ស្មាន %.2f គ.ក្រ/សប្តាហ៍ លឿនខ្លាំង។ សូមពិនិត្យផែនការជាមួយអ្នកជំនាញសុខភាព។",
                            weeklyPaceKg)
                    : String.format(
                            "Planning estimate is rapid (%.2f kg/week). Review your plan with a health professional.",
                            weeklyPaceKg);
        }

        // 7. Safe Calorie Floor Warning
        double safeFloor = isFemale ? MIN_CALORIES_FEMALE : MIN_CALORIES_MALE;
        boolean calorieWarning = dailyPlannedCalories < safeFloor;
        String calorieWarningMessage = "";
        if (calorieWarning) {
            calorieWarningMessage = isKhmer
                    ? String.format(
                            "កាឡូរីដែលបានគ្រោង (%.0f kcal/ថ្ងៃ) ទាបជាងកម្រិតពិនិត្យ (%.0f kcal)។ សូមពិនិត្យថាអ្នកបានបញ្ចូលអាហារគ្រប់ពេល និងពិគ្រោះអ្នកជំនាញសុខភាពបើចាំបាច់។",
                            dailyPlannedCalories, safeFloor)
                    : String.format(
                            "Planned intake (%.0f kcal/day) is below the review threshold (%.0f kcal). Check that all meals are planned and seek professional advice if needed.",
                            dailyPlannedCalories, safeFloor);
        }

        // 8. Direct Database Recommendations: Foods — exclude already planned meals
        Set<Integer> plannedMealIds = plannedMeals.stream()
                .filter(p -> p.getPlannerMeal() != null)
                .map(p -> p.getPlannerMeal().getPlannerMealId())
                .collect(Collectors.toSet());
        List<ForecastRecommendationItem> recommendedFoods = selectRecommendedFoods(lang, goal, plannedMealIds);

        // 9. Direct Database Recommendations: Beverages
        List<ForecastRecommendationItem> recommendedBeverages = selectRecommendedBeverages(lang, goal);

        // 10. Explain whether these figures describe planned meals or a preview target.
        String aiSummary = generateGoalSummary(
                isKhmer, isWeightLoss, plannedMeals.isEmpty(), timeframeDays,
                dailyDeficit, projectedWeightLossKg, weeklyPaceKg);

        return new WeightLossForecastResponse(
                round(weightKg, 1),
                round(isWeightLoss
                        ? Math.max(35.0, weightKg - (timeframeDays >= 28 ? 3.0 : 1.5))
                        : weightKg, 1),
                round(projectedWeightLossKg, 2),
                round(projectedEndWeightKg, 1),
                round(bmr, 0),
                round(tdee, 0),
                round(dailyPlannedCalories, 0),
                round(dailyDeficit, 0),
                timeframeDays,
                round(weeklyPaceKg, 2),
                paceStatus,
                paceDescription,
                calorieWarning,
                calorieWarningMessage,
                recommendedFoods,
                recommendedBeverages,
                aiSummary,
                plannedMeals.stream().anyMatch(plan -> plan.getPlannerMeal() != null));
    }

    /**
     * Synthesizes and saves a practical, varied weekly meal plan using Gemini.
     * Aligns daily calorie deficit to hit the user's weight loss forecast safely.
     */
    @Transactional
    public AiAutoFillPlanResponse generateAiAutoFillPlan(
            Integer userId,
            AiAutoFillPlanRequest request,
            String requestedLang) {

        final String lang = (requestedLang != null && requestedLang.equalsIgnoreCase("km")) ? "km" : "en";
        final String goal = IbmMealPlannerRecommendationService.normalizeGoal(request.goal());
        final boolean isWeightLoss = "LOSE_WEIGHT".equals(goal);

        if (isWeightLoss && request.medicalFlags().stream()
                .anyMatch(flag -> "PREGNANT_OR_BREASTFEEDING".equalsIgnoreCase(flag))) {
            throw new ResponseStatusException(BAD_REQUEST,
                    "Weight-loss auto-planning is not available during pregnancy or breastfeeding.");
        }

        // 1. Resolve User Biometrics
        Optional<WellnessProfile> wellnessOpt = userId != null ? wellnessProfileRepository.findByUser_UserId(userId)
                : Optional.empty();
        Optional<UserProfile> profileOpt = userId != null ? userProfileRepository.findByUser_UserId(userId)
                : Optional.empty();

        double weightKg = 70.0;
        double heightCm = 170.0;
        int age = 28;
        String activityLevel = "MODERATE";
        String gender = "MALE";

        if (wellnessOpt.isPresent()) {
            WellnessProfile wp = wellnessOpt.get();
            if (wp.getWeightKg() != null && wp.getWeightKg().doubleValue() > 0) {
                weightKg = wp.getWeightKg().doubleValue();
            }
            if (wp.getHeightCm() != null && wp.getHeightCm().doubleValue() > 0) {
                heightCm = wp.getHeightCm().doubleValue();
            }
            if (wp.getAgeCached() != null && wp.getAgeCached() > 0) {
                age = wp.getAgeCached().intValue();
            }
            if (wp.getActivityLevel() != null && !wp.getActivityLevel().isBlank()) {
                activityLevel = wp.getActivityLevel().trim().toUpperCase(Locale.ROOT);
            }
        }

        if (profileOpt.isPresent()) {
            UserProfile up = profileOpt.get();
            if (up.getGender() != null && !up.getGender().isBlank()) {
                gender = up.getGender().trim().toUpperCase(Locale.ROOT);
            }
            if (up.getDateOfBirth() != null && (wellnessOpt.isEmpty() || wellnessOpt.get().getAgeCached() == null)) {
                age = Math.max(12, Period.between(up.getDateOfBirth(), LocalDate.now()).getYears());
            }
        }

        boolean isFemale = gender.contains("FEMALE") || gender.contains("WOMAN") || gender.equalsIgnoreCase("F");

        // 2. Compute Mifflin-St Jeor BMR & TDEE
        double bmr = (10.0 * weightKg) + (6.25 * heightCm) - (5.0 * age) + (isFemale ? -161.0 : 5.0);
        bmr = Math.max(800.0, bmr);

        double activityMultiplier = switch (activityLevel) {
            case "SEDENTARY" -> 1.2;
            case "LIGHT" -> 1.375;
            case "MODERATE" -> 1.55;
            case "ACTIVE", "VERY_ACTIVE" -> 1.725;
            case "EXTRA_ACTIVE" -> 1.9;
            default -> 1.55;
        };
        double tdee = bmr * activityMultiplier;

        // 3. Determine Target Daily Calories & Deficit
        double safeFloor = isFemale ? MIN_CALORIES_FEMALE : MIN_CALORIES_MALE;
        double targetDailyCalories;
        if (isWeightLoss) {
            targetDailyCalories = Math.max(safeFloor, tdee - 500.0);
        } else {
            targetDailyCalories = Math.max(safeFloor, tdee);
        }

        // 4. Resolve Plan Dates and Slots
        LocalDate start = request.startDate() != null ? request.startDate() : LocalDate.now();
        int daysCount = request.days() != null ? request.days() : 7;
        List<LocalDate> dates = new ArrayList<>();
        for (int i = 0; i < daysCount; i++) {
            dates.add(start.plusDays(i));
        }

        LocalDate end = start.plusDays(daysCount - 1L);
        List<MealPlan> existingPlans = (userId != null)
                ? mealPlanRepository.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(userId, start,
                        end)
                : List.of();

        boolean fillEmptyOnly = !Boolean.FALSE.equals(request.fillEmptyOnly());
        Map<LocalDate, List<String>> slotsPerDate = new LinkedHashMap<>();
        List<String> allSlots = List.of("BREAKFAST", "LUNCH", "DINNER", "SNACK");

        for (LocalDate date : dates) {
            if (fillEmptyOnly) {
                Map<String, MealPlan> plansBySlot = existingPlans.stream()
                        .filter(p -> p.getPlanDate().equals(date))
                        .collect(Collectors.toMap(
                                p -> p.getMealType().toUpperCase(Locale.ROOT),
                                p -> p,
                                (first, ignored) -> first,
                                LinkedHashMap::new));
                Set<String> distinctMealNames = new java.util.HashSet<>();
                Set<Integer> distinctMealIds = new java.util.HashSet<>();
                Set<String> alreadyPlannedSlots = new java.util.HashSet<>();
                for (String slot : allSlots) {
                    MealPlan existing = plansBySlot.get(slot);
                    if (existing == null || existing.getPlannerMeal() == null) {
                        continue;
                    }
                    PlannerMeal meal = existing.getPlannerMeal();
                    boolean uniqueId = meal.getPlannerMealId() == null
                            || distinctMealIds.add(meal.getPlannerMealId());
                    boolean uniqueName = distinctMealNames.add(canonicalMealName(meal));
                    if (uniqueId && uniqueName) {
                        alreadyPlannedSlots.add(slot);
                    }
                }

                List<String> needed = allSlots.stream()
                        .filter(s -> !alreadyPlannedSlots.contains(s))
                        .toList();
                slotsPerDate.put(date, needed);
            } else {
                slotsPerDate.put(date, allSlots);
            }
        }

        // 5. Query candidate meals
        Map<String, PlannerMeal> uniqueCandidates = new LinkedHashMap<>();
        plannerMealRepository.findAllByOrderByNameEnAsc().stream()
                .filter(m -> Boolean.TRUE.equals(m.getActive()))
                .filter(m -> matchesDietaryPreferences(m, request))
                .forEach(meal -> uniqueCandidates.putIfAbsent(canonicalMealName(meal), meal));
        List<PlannerMeal> candidates = new ArrayList<>(uniqueCandidates.values());

        if (candidates.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST,
                    "No meals match the selected dietary restrictions.");
        }

        // 6. Gemini-first synthesis, with the existing clinical engine as a safe
        // fallback.
        Set<Integer> recentlyUsedMealIds = existingPlans.stream()
                .map(MealPlan::getPlannerMeal)
                .filter(java.util.Objects::nonNull)
                .map(PlannerMeal::getPlannerMealId)
                .filter(java.util.Objects::nonNull)
                .collect(Collectors.toSet());
        AutoFillPlanSynthesis synthesis;
        if (geminiAutoFillService != null) {
            synthesis = recentlyUsedMealIds.isEmpty()
                    ? geminiAutoFillService.synthesizeWeeklyPlan(
                            dates, slotsPerDate, candidates, targetDailyCalories, tdee, goal, lang)
                    : geminiAutoFillService.synthesizeWeeklyPlan(
                            dates, slotsPerDate, candidates, targetDailyCalories, tdee, goal, lang,
                            recentlyUsedMealIds);
        } else {
            synthesis = recentlyUsedMealIds.isEmpty()
                    ? ibmRecommendationService.synthesizeWeeklyPlan(
                            dates, slotsPerDate, candidates, targetDailyCalories, tdee, goal, lang)
                    : ibmRecommendationService.synthesizeWeeklyPlan(
                            dates, slotsPerDate, candidates, targetDailyCalories, tdee, goal, lang,
                            recentlyUsedMealIds);
        }

        // 7. Persist into meal_plans
        List<MealPlanResponse> createdResponses = new ArrayList<>();
        if (userId != null) {
            for (DaySlotSelection sel : synthesis.selections()) {
                MealPlanRequest mealReq = new MealPlanRequest(
                        sel.date(),
                        sel.slot(),
                        sel.selectedMeal().getPlannerMealId(),
                        BigDecimal.ONE);
                MealPlanResponse created = mealPlannerService.addOrReplace(userId, mealReq, lang);
                createdResponses.add(created);
            }
        }

        // 8. Return a weight projection only for the weight-loss goal.
        int timeframe = request.targetTimeframeDays() != null ? request.targetTimeframeDays() : 28;
        double totalLossKg = isWeightLoss
                ? Math.max(0.0, (synthesis.dailyDeficit() * timeframe) / KCAL_PER_KG_FAT)
                : 0.0;

        return new AiAutoFillPlanResponse(
                createdResponses,
                createdResponses.size(),
                round(synthesis.averageDailyCalories(), 0).doubleValue(),
                round(synthesis.dailyDeficit(), 0).doubleValue(),
                round(tdee, 0).doubleValue(),
                round(bmr, 0).doubleValue(),
                round(synthesis.weeklyPaceKg(), 2).doubleValue(),
                timeframe,
                round(totalLossKg, 2).doubleValue(),
                synthesis.summaryRationale(),
                goal,
                synthesis.modelUsed());
    }

    private boolean matchesDietaryPreferences(PlannerMeal meal, AiAutoFillPlanRequest request) {
        String searchable = String.join(" ",
                safeText(meal.getNameEn()),
                safeText(meal.getNameKm()),
                safeText(meal.getCategoryEn()),
                safeText(meal.getCategoryKm()),
                safeText(meal.getDescriptionEn()),
                safeText(meal.getDescriptionKm()),
                safeText(meal.getIngredientsText()),
                safeText(meal.getIngredientsTextKm()),
                safeText(meal.getTagsText()),
                safeText(meal.getTagsTextKm())).toLowerCase(Locale.ROOT);

        String diet = request.diet() == null ? "BALANCED" : request.diet().trim().toUpperCase(Locale.ROOT);
        List<String> prohibited = new ArrayList<>();
        if ("VEGETARIAN".equals(diet) || "VEGAN".equals(diet)) {
            prohibited.addAll(List.of("beef", "pork", "chicken", "fish", "shrimp", "prawn", "meat",
                    "សាច់", "ត្រី", "បង្គា"));
        }
        if ("VEGAN".equals(diet)) {
            prohibited.addAll(List.of("egg", "milk", "cheese", "yogurt", "butter", "cream", "honey",
                    "ស៊ុត", "ទឹកដោះ", "ឈីស", "យ៉ាអួ"));
        }
        if (request.medicalFlags().stream().anyMatch(flag -> "DIABETES".equalsIgnoreCase(flag))) {
            prohibited.addAll(List.of("sugary drink", "sweetened", "syrup", "soda", "soft drink"));
        }
        if (request.medicalFlags().stream().anyMatch(flag -> "HYPERTENSION".equalsIgnoreCase(flag))) {
            prohibited.addAll(List.of("high sodium", "salty", "bacon", "sausage", "processed meat"));
        }
        request.allergens().forEach(allergen -> prohibited.addAll(allergenSearchTerms(allergen)));
        prohibited.addAll(request.excludedIngredients());

        return prohibited.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(value -> value.trim().toLowerCase(Locale.ROOT))
                .noneMatch(searchable::contains);
    }

    private static List<String> allergenSearchTerms(String allergen) {
        if (allergen == null)
            return List.of();
        return switch (allergen.trim().toLowerCase(Locale.ROOT)) {
            case "peanut" -> List.of("peanut", "groundnut", "សណ្តែកដី");
            case "milk" ->
                List.of("milk", "dairy", "cheese", "yogurt", "butter", "cream", "whey", "ទឹកដោះ", "ឈីស", "យ៉ាអួ");
            case "egg" -> List.of("egg", "ស៊ុត");
            case "wheat" -> List.of("wheat", "flour", "bread", "pasta", "ស្រូវសាលី");
            case "fish" -> List.of("fish", "salmon", "tuna", "bass", "ត្រី");
            case "shrimp" -> List.of("shrimp", "prawn", "shellfish", "crab", "lobster", "បង្គា", "ក្តាម");
            case "soy" -> List.of("soy", "soya", "tofu", "សណ្តែកសៀង", "តៅហ៊ូ");
            case "tree nuts" ->
                List.of("almond", "walnut", "cashew", "pecan", "pistachio", "hazelnut", "macadamia", "tree nut");
            case "sesame" -> List.of("sesame", "tahini", "ល្ង");
            default -> List.of(allergen);
        };
    }

    private String safeText(String value) {
        return value == null ? "" : value;
    }

    private static String canonicalMealName(PlannerMeal meal) {
        String name = meal.getNameEn();
        if (name == null || name.isBlank()) {
            name = meal.getNameKm();
        }
        if (name == null || name.isBlank()) {
            return "meal-" + meal.getPlannerMealId();
        }
        return Normalizer.normalize(name, Normalizer.Form.NFKC)
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^\\p{L}\\p{N}]+", " ")
                .trim();
    }

    /**
     * Ranks planner meals for the selected health goal.
     */
    private List<ForecastRecommendationItem> selectRecommendedFoods(
            String lang, String goal, Set<Integer> excludedPlannerMealIds) {
        final boolean isKhmer = "km".equals(lang);
        final boolean isWeightLoss = "LOSE_WEIGHT".equals(goal);
        List<PlannerMeal> allMeals = plannerMealRepository.findAllByOrderByNameEnAsc();
        if (allMeals == null || allMeals.isEmpty()) {
            return List.of();
        }

        return allMeals.stream()
                .filter(m -> m.getActive() != null && m.getActive())
                .filter(m -> !excludedPlannerMealIds.contains(m.getPlannerMealId()))
                .sorted(Comparator
                        .comparingDouble((PlannerMeal m) -> forecastFoodScore(m, isWeightLoss)).reversed()
                        .thenComparing(Comparator
                                .comparing((PlannerMeal m) -> m.getImageUrl() != null && !m.getImageUrl().isBlank())
                                .reversed())
                        .thenComparing(m -> m.getCalories() != null ? m.getCalories().doubleValue() : 999.0))
                .limit(4)
                .map(m -> {
                    String name = isKhmer && m.getNameKm() != null && !m.getNameKm().isBlank() ? m.getNameKm()
                            : m.getNameEn();
                    String category = isKhmer && m.getCategoryKm() != null && !m.getCategoryKm().isBlank()
                            ? m.getCategoryKm()
                            : m.getCategoryEn();
                    int protein = m.getProteinGrams() != null ? m.getProteinGrams().intValue() : 0;
                    int cal = m.getCalories() != null ? m.getCalories().intValue() : 0;

                    String source = "";
                    String tags = m.getTagsText() != null ? m.getTagsText() : "";
                    if (tags.contains("BBC Good Food"))
                        source = "BBC Good Food";
                    else if (tags.contains("EatingWell"))
                        source = "EatingWell";
                    else if (tags.contains("Healthline"))
                        source = "Healthline";

                    String sourcePrefix = source.isEmpty() ? ""
                            : (isKhmer ? " (ប្រភព " + source + ")" : " (" + source + ")");
                    String rationale;
                    if (isWeightLoss) {
                        rationale = isKhmer
                                ? String.format(
                                        "សមស្របសម្រាប់សម្រកទម្ងន់%s៖ %d kcal និងប្រូតេអ៊ីន %dg ក្នុងមួយចំណែក។ ជួយឱ្យឆ្អែតបានយូរ រក្សាសាច់ដុំ និងរក្សាឱនភាពកាឡូរីប្រចាំថ្ងៃ។",
                                        sourcePrefix, cal, protein)
                                : String.format(
                                        "Weight-loss match%s: %d kcal and %dg protein per serving. High protein supports muscle retention while keeping you in your calorie deficit.",
                                        sourcePrefix, cal, protein);
                    } else {
                        int carbs = m.getCarbsGrams() != null ? m.getCarbsGrams().intValue() : 0;
                        int fat = m.getFatGrams() != null ? m.getFatGrams().intValue() : 0;
                        rationale = isKhmer
                                ? String.format(
                                        "សមស្របសម្រាប់រក្សាទម្ងន់%s៖ %d kcal (ប្រូតេអ៊ីន %dg, កាបូ %dg, ខ្លាញ់ %dg)។ តុល្យភាពសារធាតុចិញ្ចឹមផ្តល់ថាមពលថេរពេញមួយថ្ងៃ និងរក្សាទម្ងន់ឱ្យនៅថេរ។",
                                        sourcePrefix, cal, protein, carbs, fat)
                                : String.format(
                                        "Maintenance match%s: %d kcal (%dg protein, %dg carbs, %dg fat). Balanced macros deliver sustained energy and maintain steady body weight.",
                                        sourcePrefix, cal, protein, carbs, fat);
                    }

                    return new ForecastRecommendationItem(
                            "FOOD",
                            m.getPlannerMealId(),
                            "planner_meals",
                            name,
                            category,
                            m.getCalories() != null ? m.getCalories() : BigDecimal.ZERO,
                            m.getProteinGrams() != null ? m.getProteinGrams() : BigDecimal.ZERO,
                            m.getCarbsGrams() != null ? m.getCarbsGrams() : BigDecimal.ZERO,
                            m.getFatGrams() != null ? m.getFatGrams() : BigDecimal.ZERO,
                            "serving",
                            BigDecimal.ONE,
                            m.getImageUrl() != null ? m.getImageUrl() : "",
                            rationale,
                            "Goal-based nutrition");
                })
                .toList();
    }

    /**
     * Ranks beverages from food_nutrition for the selected health goal.
     */
    private List<ForecastRecommendationItem> selectRecommendedBeverages(String lang, String goal) {
        final boolean isKhmer = "km".equals(lang);
        final boolean isWeightLoss = "LOSE_WEIGHT".equals(goal);
        List<FoodNutrition> allFoods = foodNutritionRepository.findAllByActiveTrue();
        if (allFoods == null || allFoods.isEmpty()) {
            return List.of();
        }

        // Keywords identifying beverages
        Set<String> beverageKeywords = Set.of("tea", "coffee", "water", "juice", "smoothie", "drink", "lime", "lemon",
                "coconut", "matcha", "infusion");

        List<FoodNutrition> candidates = allFoods.stream()
                .filter(f -> {
                    String name = f.getName().toLowerCase(Locale.ROOT);
                    String aliases = f.getAliases() != null ? f.getAliases().toLowerCase(Locale.ROOT) : "";
                    String unit = f.getServingUnit() != null ? f.getServingUnit().toLowerCase(Locale.ROOT) : "";

                    boolean isDrink = beverageKeywords.stream().anyMatch(k -> name.contains(k) || aliases.contains(k))
                            || unit.equals("cup") || unit.equals("glass") || unit.equals("can")
                            || unit.equals("bottle");

                    // Filter out high-sugar sodas and sweet bubble teas (> 20g sugar)
                    boolean highSugar = f.getSugar() != null && f.getSugar().doubleValue() > 20.0;
                    return isDrink && !highSugar;
                })
                .sorted(Comparator
                        .comparingDouble((FoodNutrition f) -> beverageGoalScore(f, isWeightLoss)).reversed()
                        .thenComparing(Comparator
                                .comparing((FoodNutrition f) -> f.getImageUrl() != null && !f.getImageUrl().isBlank())
                                .reversed()))
                .limit(4)
                .toList();

        return candidates.stream().map(f -> {
            String name = f.getName();
            String nameKm = resolveKhmerBeverageName(name);
            String displayName = isKhmer ? nameKm : name;

            String rationale = createBeverageRationale(f, isKhmer, isWeightLoss);

            return new ForecastRecommendationItem(
                    "BEVERAGE",
                    f.getId(),
                    "food_nutrition",
                    displayName,
                    isKhmer ? "ភេសជ្ជៈសុខភាព" : "Healthy Beverage",
                    f.getCalories() != null ? f.getCalories() : BigDecimal.ZERO,
                    f.getProtein() != null ? f.getProtein() : BigDecimal.ZERO,
                    f.getCarbs() != null ? f.getCarbs() : BigDecimal.ZERO,
                    f.getFat() != null ? f.getFat() : BigDecimal.ZERO,
                    f.getServingUnit() != null ? f.getServingUnit() : "glass",
                    f.getServingSize() != null ? f.getServingSize() : BigDecimal.ONE,
                    f.getImageUrl() != null ? f.getImageUrl() : "",
                    rationale,
                    "Goal-based nutrition");
        }).toList();
    }

    private static String resolveKhmerBeverageName(String englishName) {
        String lower = englishName.toLowerCase(Locale.ROOT);
        if (lower.contains("matcha"))
            return "តែ Matcha";
        if (lower.contains("coconut"))
            return "ទឹកដូង";
        if (lower.contains("cucumber"))
            return "ទឹកត្រសក់";
        if (lower.contains("turmeric") && lower.contains("ginger"))
            return "តែរមៀតខ្ញី";
        if (lower.contains("turmeric"))
            return "តែរមៀត";
        if (lower.contains("ginger"))
            return "តែខ្ញី";
        if (lower.contains("green tea"))
            return "តែបៃតង";
        if (lower.contains("black coffee"))
            return "កាហ្វេខ្មៅ";
        if (lower.contains("water"))
            return "ទឹកបរិសុទ្ធ";
        if (lower.contains("orange juice"))
            return "ទឹកក្រូច";
        if (lower.contains("coffee with milk"))
            return "កាហ្វេទឹកដោះគោ";
        if (lower.contains("smoothie"))
            return "ទឹកផ្លែឈើក្រឡុក";
        return englishName;
    }

    private static String createBeverageRationale(FoodNutrition drink, boolean isKhmer, boolean isWeightLoss) {
        int calories = drink.getCalories() != null ? drink.getCalories().intValue() : 0;
        String sugar = drink.getSugar() != null
                ? String.format(Locale.ROOT, isKhmer ? ", ស្ករ %.0fg" : ", %.0fg sugar",
                        drink.getSugar().doubleValue())
                : "";
        if (isWeightLoss) {
            return isKhmer
                    ? String.format(Locale.ROOT,
                            "ភេសជ្ជៈសម្រាប់គ្រប់គ្រងកាឡូរី៖ %d kcal%s ក្នុងមួយចំណែក។ ជួយផ្តល់ជាតិទឹក គ្មានកាឡូរីលើស និងមិនធ្វើឱ្យរាំងស្ទះដល់ការដុតរំលាយជាតិខ្លាញ់។",
                            calories, sugar)
                    : String.format(Locale.ROOT,
                            "Calorie-aware choice: %d kcal%s per serving. Hydrating and virtually free of empty calories, supporting fat loss.",
                            calories, sugar);
        }
        return isKhmer
                ? String.format(Locale.ROOT,
                        "ភេសជ្ជៈសម្រាប់រក្សាតុល្យភាព៖ %d kcal%s ក្នុងមួយចំណែក។ សម្បូរទៅដោយសារធាតុប្រឆាំងអុកស៊ីតកម្ម ជួយឱ្យស្រស់ស្រាយ និងទ្រទ្រង់តុល្យភាពសុខភាពប្រចាំថ្ងៃ។",
                        calories, sugar)
                : String.format(Locale.ROOT,
                        "Maintenance balance: %d kcal%s per serving. Rich in antioxidants and minerals, sustaining daily vitality and fluid balance.",
                        calories, sugar);
    }

    private static String generateGoalSummary(boolean isKhmer, boolean isWeightLoss, boolean isPreview,
            int days, double deficit, double weightLossKg, double paceKg) {
        if (isPreview) {
            if (!isWeightLoss) {
                return isKhmer
                        ? "នេះជាការបង្ហាញសាកល្បងតាមតម្រូវការថាមពលប៉ាន់ស្មានរបស់អ្នក។ បន្ថែមអាហារក្នុងផែនការដើម្បីប្រៀបធៀបជាក់ស្តែង។"
                        : "This is a preview based on estimated maintenance needs. Add meals to compare your actual plan.";
            }
            return isKhmer
                    ? "នេះជាការបង្ហាញសាកល្បងតាមគោលដៅកាឡូរីប៉ាន់ស្មាន មិនមែនលទ្ធផលពីអាហារដែលអ្នកបានគ្រោងទុកទេ។ បន្ថែមអាហារដើម្បីឱ្យការប៉ាន់ស្មានមានន័យ។"
                    : "This is a preview based on an estimated calorie target, not meals you have planned. Add meals for a meaningful estimate.";
        }
        if (!isWeightLoss) {
            double gap = Math.abs(deficit);
            if (gap <= 200.0) {
                return isKhmer
                        ? "ផែនការអាហាររបស់អ្នកស្ថិតជិតតម្រូវការថាមពលប្រចាំថ្ងៃ។ អាហារដែលបានណែនាំផ្តោតលើប្រូតេអ៊ីន កាបូអ៊ីដ្រាត និងខ្លាញ់មានតុល្យភាពសម្រាប់ថាមពលថេរ។"
                        : "Your planned meals are close to estimated maintenance energy needs. Include every meal for a useful comparison; recommendations prioritize balanced nutrients.";
            }
            return isKhmer
                    ? String.format(
                            "ផែនការរបស់អ្នកខុសពីតម្រូវការរក្សាទម្ងន់ប្រហែល %.0f kcal/ថ្ងៃ។ កែទំហំចំណែក និងជ្រើសអាហារមានតុល្យភាពដើម្បីរក្សាថាមពលឱ្យថេរ។",
                            gap)
                    : String.format(
                            "Planned meals differ from estimated maintenance needs by about %.0f kcal/day. Check for missing meals before adjusting portions.",
                            gap);
        }
        if (deficit <= 0) {
            return isKhmer
                    ? "ផែនការអាហារបច្ចុប្បន្នរបស់អ្នកស្ថិតក្នុងកម្រិតថែរក្សា ឬលើសកាឡូរីបន្តិច។ ដើម្បីសម្រកទម្ងន់ សូមពិចារណាជ្រើសរើសមុខម្ហូបដែលមានប្រូតេអ៊ីនខ្ពស់ និងបន្លែច្រើន។"
                    : "Your current meal plan is at maintenance or slight surplus. To initiate steady fat loss, consider replacing high-calorie sides with fibrous vegetables and lean proteins.";
        }

        if (isKhmer) {
            return String.format(
                    "តាមកាឡូរីដែលបានគ្រោង ឱនភាពប្រហែល %.0f kcal/ថ្ងៃ ស្មើនឹងការប៉ាន់ស្មាន %.1f គ.ក្រ ក្នុង %d ថ្ងៃ (%.2f គ.ក្រ/សប្តាហ៍)។ លទ្ធផលពិតអាចខុសគ្នា ហើយត្រូវបញ្ចូលអាហារគ្រប់ពេលដើម្បីឱ្យការប៉ាន់ស្មានមានន័យ។",
                    deficit, weightLossKg, days, paceKg);
        } else {
            return String.format(
                    "Based on your planned daily deficit of %.0f kcal, the planning estimate is approximately %.1f kg over %d days (~%.2f kg/week). Include every meal; actual results vary and are not guaranteed.",
                    deficit, weightLossKg, days, paceKg);
        }
    }

    private static double forecastFoodScore(PlannerMeal meal, boolean isWeightLoss) {
        double calories = meal.getCalories() != null ? meal.getCalories().doubleValue() : 0.0;
        double protein = meal.getProteinGrams() != null ? meal.getProteinGrams().doubleValue() : 0.0;
        double carbs = meal.getCarbsGrams() != null ? meal.getCarbsGrams().doubleValue() : 0.0;
        double fat = meal.getFatGrams() != null ? meal.getFatGrams().doubleValue() : 0.0;
        if (isWeightLoss) {
            double caloriePenalty = Math.max(0.0, calories - 550.0) * 0.12;
            return (proteinDensity(meal) * 7.0) - caloriePenalty;
        }

        double calorieFit = Math.max(0.0, 100.0 - (Math.abs(calories - 500.0) * 0.20));
        double macroCalories = (protein * 4.0) + (carbs * 4.0) + (fat * 9.0);
        if (macroCalories <= 0.0) {
            return calorieFit;
        }
        double proteinRatio = (protein * 4.0) / macroCalories;
        double carbRatio = (carbs * 4.0) / macroCalories;
        double fatRatio = (fat * 9.0) / macroCalories;
        double balancePenalty = (Math.abs(proteinRatio - 0.25)
                + Math.abs(carbRatio - 0.45)
                + Math.abs(fatRatio - 0.30)) * 80.0;
        return calorieFit + Math.max(0.0, 100.0 - balancePenalty);
    }

    private static double beverageGoalScore(FoodNutrition drink, boolean isWeightLoss) {
        double calories = drink.getCalories() != null ? drink.getCalories().doubleValue() : 0.0;
        double sugar = drink.getSugar() != null ? drink.getSugar().doubleValue() : 0.0;
        if (isWeightLoss) {
            return 100.0 - (calories * 0.35) - (sugar * 2.5);
        }
        return 100.0 - (Math.abs(calories - 60.0) * 0.12) - (sugar * 1.5);
    }

    private static double proteinDensity(PlannerMeal meal) {
        if (meal == null || meal.getCalories() == null || meal.getProteinGrams() == null)
            return 0.0;
        double cal = meal.getCalories().doubleValue();
        double pro = meal.getProteinGrams().doubleValue();
        return cal > 0 ? (pro / cal) * 100.0 : 0.0;
    }

    private static BigDecimal round(double value, int scale) {
        return BigDecimal.valueOf(value).setScale(scale, RoundingMode.HALF_UP);
    }
}
