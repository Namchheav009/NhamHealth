package com.nhamhealth.nhamhealth_api.controller.api;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;

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
import com.nhamhealth.nhamhealth_api.service.meal.PlannerMealContent;
import com.nhamhealth.nhamhealth_api.service.ai.IbmMealPlannerRecommendationService;

import jakarta.validation.Valid;

@RestController
@RequestMapping({ "/api/v1/meal-planner", "/api/meal-planner" })
public class WeeklyMealPlannerApiController {
    private final WeeklyMealRecommendationRepository recommendations;
    private final MealPlannerForecastService forecastService;
    private final IbmMealPlannerRecommendationService rankingService;

    @Autowired
    public WeeklyMealPlannerApiController(
            WeeklyMealRecommendationRepository recommendations,
            MealPlannerForecastService forecastService,
            IbmMealPlannerRecommendationService rankingService) {
        this.recommendations = recommendations;
        this.forecastService = forecastService;
        this.rankingService = rankingService;
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
        return ResponseEntity.ok(forecastService.recommendMeal(userId(jwt), request, lang));
    }

    @GetMapping("/recommendations")
    @Transactional(readOnly = true)
    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false) String dayOfWeek,
            @RequestParam(required = false) LocalDate date,
            @RequestParam(defaultValue = "en") String lang,
            @RequestParam(defaultValue = "MAINTAIN_HEALTH") String goal) {
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
        List<WeeklyMealRecommendation> eligible = list.stream()
                .filter(row -> row.getPlannerMeal().supportsWeightGoal(normalizedGoal))
                .toList();
        List<WeeklyMealRecommendation> ranked = rankingService == null
                ? eligible
                : rankingService.rank(userId(jwt), normalizedGoal, eligible);
        return ResponseEntity.ok(ranked.stream().map(row -> response(row, lang)).toList());
    }

    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(
            String dayOfWeek, LocalDate date, String lang) {
        return recommendations(null, dayOfWeek, date, lang, "MAINTAIN_HEALTH");
    }

    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(String lang) {
        return recommendations(null, null, null, lang, "MAINTAIN_HEALTH");
    }

    private Integer userId(Jwt jwt) {
        if (jwt == null)
            return null;
        Number id = jwt.getClaim("userId");
        return id == null ? null : id.intValue();
    }

    private WeeklyMealRecommendationResponse response(WeeklyMealRecommendation row, String lang) {
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
                row.getNote(), row.getSortOrder(), categoryIds);
    }
}
