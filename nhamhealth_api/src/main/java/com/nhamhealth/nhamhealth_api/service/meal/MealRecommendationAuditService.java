package com.nhamhealth.nhamhealth_api.service.meal;

import java.util.Map;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.request.MealRecommendationRequest;
import com.nhamhealth.nhamhealth_api.dto.response.MealPlannerAiRecommendationResponse;
import com.nhamhealth.nhamhealth_api.dto.response.WeeklyMealRecommendationResponse;

@Service
public class MealRecommendationAuditService {
    private final JdbcTemplate jdbc;
    private final ObjectMapper json = new ObjectMapper();

    public MealRecommendationAuditService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional
    public void record(Integer userId, MealRecommendationRequest request,
            MealPlannerAiRecommendationResponse response) {
        if (userId == null || response == null || response.recommendedMeal() == null) return;
        WeeklyMealRecommendationResponse meal = response.recommendedMeal();
        double score = nutritionScore(request.goal(), meal);
        jdbc.update("""
                insert into public.meal_recommendation_audits
                    (user_id, planner_meal_id, weight_goal, total_score, nutrition_score,
                     preference_score, adherence_score, diversity_score, explanation_en,
                     input_snapshot, model_version, created_at)
                values (?, ?, ?, ?, ?, ?, ?, ?, ?, cast(? as jsonb), ?, current_timestamp)
                """,
                userId, meal.plannerMealId(), request.goal(), score, score,
                preferenceScore(request), null, null, response.aiRationale(),
                snapshot(request), response.modelUsed() == null ? "RULE_BASED" : response.modelUsed());
    }

    private double nutritionScore(String goal, WeeklyMealRecommendationResponse meal) {
        double calories = meal.calories() == null ? 0 : meal.calories().doubleValue();
        double protein = meal.proteinGrams() == null ? 0 : meal.proteinGrams().doubleValue();
        double target = "GAIN_WEIGHT".equalsIgnoreCase(goal) ? 600 :
                ("LOSE_WEIGHT".equalsIgnoreCase(goal) ? 350 : 500);
        double calorieFit = Math.max(0, 60 - Math.abs(calories - target) * 0.12);
        return Math.min(100, Math.round((calorieFit + Math.min(40, protein * 1.3)) * 100.0) / 100.0);
    }

    private double preferenceScore(MealRecommendationRequest request) {
        int explicitSignals = (request.diet() != null && !"BALANCED".equals(request.diet()) ? 1 : 0)
                + request.allergens().size() + request.excludedIngredients().size() + request.medicalFlags().size();
        return Math.min(100, 50 + explicitSignals * 10);
    }

    private String snapshot(MealRecommendationRequest request) {
        try {
            return json.writeValueAsString(Map.of(
                    "date", request.date().toString(), "slot", request.slot(), "goal", request.goal(),
                    "diet", request.diet(), "allergens", request.allergens(),
                    "excludedIngredients", request.excludedIngredients(), "medicalFlags", request.medicalFlags()));
        } catch (JsonProcessingException ignored) {
            return "{}";
        }
    }
}
