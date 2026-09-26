package com.nhamhealth.nhamhealth_api.controller.api;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.request.AiAutoFillPlanRequest;
import com.nhamhealth.nhamhealth_api.dto.request.MealRecommendationRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AiAutoFillPlanResponse;
import com.nhamhealth.nhamhealth_api.dto.response.MealPlannerAiRecommendationResponse;
import com.nhamhealth.nhamhealth_api.dto.response.WeeklyMealRecommendationResponse;
import com.nhamhealth.nhamhealth_api.dto.response.WeightLossForecastResponse;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;
import com.nhamhealth.nhamhealth_api.service.meal.MealPlannerForecastService;
import com.nhamhealth.nhamhealth_api.service.meal.MealRecommendationAuditService;
import com.nhamhealth.nhamhealth_api.service.meal.PlannerMealContent;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService;

import jakarta.validation.Valid;

@RestController
@RequestMapping({ "/api/v1/meal-planner", "/api/meal-planner" })
public class WeeklyMealPlannerApiController {
    private final WeeklyMealRecommendationRepository recommendations;
    private final MealPlannerForecastService forecastService;
    private final IbmMealPlannerRecommendationService rankingService;
    private final MealRecommendationAuditService auditService;

    @Autowired
    public WeeklyMealPlannerApiController(
            WeeklyMealRecommendationRepository recommendations,
            MealPlannerForecastService forecastService,
            IbmMealPlannerRecommendationService rankingService,
            MealRecommendationAuditService auditService) {
        this.recommendations = recommendations;
        this.forecastService = forecastService;
        this.rankingService = rankingService;
        this.auditService = auditService;
    }

    public WeeklyMealPlannerApiController(
            WeeklyMealRecommendationRepository recommendations,
            MealPlannerForecastService forecastService,
            IbmMealPlannerRecommendationService rankingService) {
        this(recommendations, forecastService, rankingService, null);
    }

    /** Compatibility constructor for existing unit tests. The former ranking
     * dependency is intentionally ignored: scheduled meals are admin curated. */
    public WeeklyMealPlannerApiController(
            WeeklyMealRecommendationRepository recommendations,
            Object ignoredRankingDependency,
            MealPlannerForecastService forecastService) {
        this(recommendations, forecastService,
                ignoredRankingDependency instanceof IbmMealPlannerRecommendationService service ? service : null);
    }

    public WeeklyMealPlannerApiController(WeeklyMealRecommendationRepository recommendations) {
        this(recommendations, (MealPlannerForecastService) null, (IbmMealPlannerRecommendationService) null);
    }

    @GetMapping("/weight-loss-forecast")
    public ResponseEntity<WeightLossForecastResponse> forecast(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(defaultValue = "28") Integer days,
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(defaultValue = "en") String lang,
            @RequestParam(defaultValue = "LOSE_WEIGHT") String goal) {
        if (forecastService == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(forecastService.calculateForecast(userId(jwt), days, startDate, lang, goal));
    }

    @PostMapping("/ai-autofill")
    @Transactional
    public ResponseEntity<AiAutoFillPlanResponse> aiAutoFill(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AiAutoFillPlanRequest request,
            @RequestParam(defaultValue = "en") String lang) {
        if (forecastService == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(forecastService.generateAiAutoFillPlan(userId(jwt), request, lang));
    }

    @PostMapping("/recommend-meal")
    @Transactional(readOnly = true)
    public ResponseEntity<MealPlannerAiRecommendationResponse> recommendMeal(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody MealRecommendationRequest request,
            @RequestParam(defaultValue = "en") String lang) {
        if (forecastService == null) {
            return ResponseEntity.notFound().build();
        }
        Integer currentUserId = userId(jwt);
        MealPlannerAiRecommendationResponse response = forecastService.recommendMeal(currentUserId, request, lang);
        if (auditService != null && currentUserId != null) {
            auditService.record(currentUserId, request, response);
        }
        return ResponseEntity.ok(response);
    }

    @GetMapping("/recommendations")
    @Transactional(readOnly = true)
    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String dayOfWeek,
            @RequestParam(required = false) LocalDate date,
            @RequestParam(defaultValue = "en") String lang,
            @RequestParam(defaultValue = "MAINTAIN_HEALTH") String goal,
            @RequestParam(defaultValue = "BALANCED") String diet,
            @RequestParam(required = false) List<String> allergens) {
        String targetDay = dayOfWeek;
        if ((targetDay == null || targetDay.isBlank()) && date != null) {
            targetDay = date.getDayOfWeek().name();
        }

        List<WeeklyMealRecommendation> list;
        if (targetDay != null && !targetDay.isBlank()) {
            list = recommendations
                    .findAllByActiveTrueAndPlannerMealActiveTrueAndDayOfWeekInOrderBySortOrderAscRecommendationIdAsc(
                            List.of("ALL", targetDay.trim().toUpperCase(Locale.ROOT)));
        } else {
            list = recommendations
                    .findAllByActiveTrueAndPlannerMealActiveTrueOrderBySortOrderAscRecommendationIdAsc();
        }

        String normalizedGoal = IbmMealPlannerRecommendationService.normalizeGoal(goal);
        String normalizedDiet = diet == null ? "BALANCED" : diet.trim().toUpperCase(Locale.ROOT);
        Set<String> excludedAllergens = allergens == null ? Set.of() : allergens.stream()
                .filter(value -> value != null && !value.isBlank())
                .map(WeeklyMealPlannerApiController::normalizeAllergen)
                .collect(Collectors.toSet());
        List<WeeklyMealRecommendation> eligible = list.stream()
                .filter(row -> row.getPlannerMeal().supportsWeightGoal(normalizedGoal))
                .filter(row -> supportsDiet(row.getPlannerMeal(), normalizedDiet))
                .filter(row -> hasNoExcludedAllergen(row.getPlannerMeal(), excludedAllergens))
                .toList();
        List<WeeklyMealRecommendation> ranked = rankingService == null
                ? eligible
                : rankingService.rankLocally(normalizedGoal, eligible);
        return ResponseEntity.ok(ranked.stream().map(row -> response(row, lang, normalizedGoal)).toList());
    }

    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(
            String dayOfWeek, LocalDate date, String lang) {
        return recommendations(null, dayOfWeek, date, lang, "MAINTAIN_HEALTH", "BALANCED", List.of());
    }

    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(String lang) {
        return recommendations(null, null, null, lang, "MAINTAIN_HEALTH", "BALANCED", List.of());
    }

    private Integer userId(Jwt jwt) {
        if (jwt == null)
            return null;
        Number id = jwt.getClaim("userId");
        return id == null ? null : id.intValue();
    }

    private WeeklyMealRecommendationResponse response(WeeklyMealRecommendation row, String lang, String goal) {
        PlannerMeal meal = row.getPlannerMeal();
        List<Integer> categoryIds = meal.getCategoryIds() != null
                ? meal.getCategoryIds().stream().sorted().toList()
                : (meal.getCategory() != null ? List.of(meal.getCategory().getCategoryId()) : List.of());
        return new WeeklyMealRecommendationResponse(
                row.getRecommendationId(), row.getDayOfWeek(), row.getMealSlot(),
                meal.getPlannerMealId(), meal.name(lang), meal.getImageUrl(),
                meal.getCalories(), meal.getProteinGrams(), meal.getCarbsGrams(),
                meal.getFatGrams(), meal.getCategory() != null ? meal.getCategory().getCategoryId() : null,
                meal.category(lang), meal.description(lang),
                meal.getCookingTimeMinutes(), "", PlannerMealContent.ingredients(meal, lang),
                PlannerMealContent.instructions(meal, lang), PlannerMealContent.tags(meal, lang),
                row.getNote(), row.getSortOrder(), categoryIds,
                meal.getFiberGrams(), meal.getSugarGrams(), meal.getSodiumMg(),
                meal.getSaturatedFatGrams(), meal.getServingSize(), meal.getServingUnit(),
                meal.getNutritionDataQuality(),
                meal.getDietTypes().stream().map(type -> type.getCode()).sorted().toList(),
                meal.getAllergens().stream().map(allergen -> allergen.getCode()).sorted().toList(),
                whyRecommended(meal, goal, lang));
    }

    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(
            Jwt jwt, String dayOfWeek, LocalDate date, String lang, String goal) {
        return recommendations(jwt, dayOfWeek, date, lang, goal, "BALANCED", List.of());
    }

    private static boolean supportsDiet(PlannerMeal meal, String diet) {
        if ("BALANCED".equals(diet)) return true;
        if (meal.getDietTypes().stream().anyMatch(type -> diet.equalsIgnoreCase(type.getCode()))) return true;
        String searchable = String.join(" ",
                safe(meal.getNameEn()), safe(meal.getDescriptionEn()),
                safe(meal.getIngredientsText()), safe(meal.getTagsText())).toLowerCase(Locale.ROOT);
        if ("VEGETARIAN".equals(diet) || "VEGAN".equals(diet)) {
            if (containsAny(searchable, "beef", "pork", "chicken", "fish", "salmon", "tuna",
                    "shrimp", "prawn", "crab", "meat")) return false;
        }
        if ("VEGAN".equals(diet)) {
            return !containsAny(searchable, "egg", "milk", "cheese", "yogurt", "butter", "cream", "honey");
        }
        return false;
    }

    private static boolean containsAny(String text, String... terms) {
        for (String term : terms) if (text.contains(term)) return true;
        return false;
    }

    private static String safe(String value) { return value == null ? "" : value; }

    private static boolean hasNoExcludedAllergen(PlannerMeal meal, Set<String> excluded) {
        if (excluded.isEmpty()) return true;
        return meal.getAllergens().stream()
                .map(allergen -> normalizeAllergen(allergen.getCode()))
                .noneMatch(excluded::contains);
    }

    private static String normalizeAllergen(String value) {
        if (value == null) return "";
        String normalized = value.trim().toUpperCase(Locale.ROOT).replace(' ', '_');
        if ("SHRIMP".equals(normalized)) return "SHELLFISH";
        if ("TREE_NUTS".equals(normalized)) return "TREE_NUT";
        return normalized;
    }

    private static String whyRecommended(PlannerMeal meal, String goal, String lang) {
        int calories = meal.getCalories() == null ? 0 : meal.getCalories().intValue();
        int protein = meal.getProteinGrams() == null ? 0 : meal.getProteinGrams().intValue();
        boolean khmer = "km".equalsIgnoreCase(lang);
        if ("GAIN_WEIGHT".equals(goal)) {
            return khmer
                    ? "សមស្របនឹងគោលដៅបង្កើនទម្ងន់៖ " + calories + " kcal និងប្រូតេអ៊ីន " + protein + "g ក្នុងមួយចំណែក។"
                    : "Gain-weight match: " + calories + " kcal and " + protein + "g protein per serving.";
        }
        if ("LOSE_WEIGHT".equals(goal)) {
            return khmer
                    ? "សមស្របនឹងគោលដៅសម្រកទម្ងន់៖ " + calories + " kcal និងប្រូតេអ៊ីន " + protein + "g ក្នុងមួយចំណែក។"
                    : "Weight-loss match: " + calories + " kcal and " + protein + "g protein per serving.";
        }
        return khmer
                ? "អាហារមានតុល្យភាព៖ " + calories + " kcal និងប្រូតេអ៊ីន " + protein + "g ក្នុងមួយចំណែក។"
                : "Balanced match: " + calories + " kcal and " + protein + "g protein per serving.";
    }
}
