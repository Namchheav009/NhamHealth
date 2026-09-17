package com.nhamhealth.nhamhealth_api.controller.api;

import java.time.LocalDate;
import java.util.List;
import java.util.Locale;

import org.springframework.http.ResponseEntity;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.WeeklyMealRecommendationResponse;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;
import com.nhamhealth.nhamhealth_api.service.meal.PlannerMealContent;

@RestController
@RequestMapping({ "/api/v1/meal-planner", "/api/meal-planner" })
public class WeeklyMealPlannerApiController {
    private final WeeklyMealRecommendationRepository recommendations;

    public WeeklyMealPlannerApiController(WeeklyMealRecommendationRepository recommendations) {
        this.recommendations = recommendations;
    }

    @GetMapping("/recommendations")
    @Transactional(readOnly = true)
    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(
            @RequestParam(required = false) String dayOfWeek,
            @RequestParam(required = false) LocalDate date,
            @RequestParam(defaultValue = "en") String lang) {
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

        return ResponseEntity.ok(list.stream().map(row -> response(row, lang)).toList());
    }

    public ResponseEntity<List<WeeklyMealRecommendationResponse>> recommendations(String lang) {
        return recommendations(null, null, lang);
    }

    private WeeklyMealRecommendationResponse response(WeeklyMealRecommendation row, String lang) {
        PlannerMeal meal = row.getPlannerMeal();
        return new WeeklyMealRecommendationResponse(
                row.getRecommendationId(), row.getDayOfWeek(), row.getMealSlot(),
                meal.getPlannerMealId(), meal.name(lang), meal.getImageUrl(),
                meal.getCalories(), meal.getProteinGrams(), meal.getCarbsGrams(),
                meal.getFatGrams(), meal.getCategory().getCategoryId(),
                meal.category(lang), meal.description(lang),
                meal.getCookingTimeMinutes(), "", PlannerMealContent.ingredients(meal, lang),
                PlannerMealContent.instructions(meal), PlannerMealContent.tags(meal),
                row.getNote(), row.getSortOrder());
    }
}
