package com.nhamhealth.nhamhealth_api.service.meal;

import java.util.Locale;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.MealPlanFeedbackRequest;
import com.nhamhealth.nhamhealth_api.dto.response.MealPlanFeedbackResponse;
import com.nhamhealth.nhamhealth_api.entity.MealPlan;
import com.nhamhealth.nhamhealth_api.entity.MealPlanFeedback;
import com.nhamhealth.nhamhealth_api.repository.meal.MealPlanFeedbackRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealPlanRepository;

@Service
public class MealPlanFeedbackService {
    private final MealPlanRepository plans;
    private final MealPlanFeedbackRepository feedback;

    public MealPlanFeedbackService(MealPlanRepository plans, MealPlanFeedbackRepository feedback) {
        this.plans = plans;
        this.feedback = feedback;
    }

    @Transactional
    public MealPlanFeedbackResponse save(Integer userId, Integer mealPlanId, MealPlanFeedbackRequest request) {
        MealPlan plan = plans.findByMealPlanIdAndUserUserId(mealPlanId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Meal plan not found."));
        String outcome = request.outcome().trim().toUpperCase(Locale.ROOT);
        if (!outcome.equals("EATEN") && !outcome.equals("PARTIALLY_EATEN") && !outcome.equals("SKIPPED")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Unsupported feedback outcome.");
        }
        MealPlanFeedback value = feedback.findByMealPlanMealPlanIdAndUserUserId(mealPlanId, userId)
                .orElseGet(MealPlanFeedback::new);
        value.setMealPlan(plan);
        value.setUser(plan.getUser());
        value.setRating(request.rating());
        value.setOutcome(outcome);
        value.setSkipReason(outcome.equals("SKIPPED") ? clean(request.skipReason()) : null);
        value.setHungerBefore(request.hungerBefore());
        value.setFullnessAfter(request.fullnessAfter());
        value.setCommentText(clean(request.comment()));
        return response(feedback.save(value));
    }

    @Transactional(readOnly = true)
    public MealPlanFeedbackResponse get(Integer userId, Integer mealPlanId) {
        plans.findByMealPlanIdAndUserUserId(mealPlanId, userId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Meal plan not found."));
        return feedback.findByMealPlanMealPlanIdAndUserUserId(mealPlanId, userId)
                .map(this::response).orElse(null);
    }

    private MealPlanFeedbackResponse response(MealPlanFeedback value) {
        return new MealPlanFeedbackResponse(value.getId(), value.getMealPlan().getMealPlanId(), value.getRating(),
                value.getOutcome(), value.getSkipReason(), value.getHungerBefore(), value.getFullnessAfter(),
                value.getCommentText(), value.getUpdatedAt());
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
