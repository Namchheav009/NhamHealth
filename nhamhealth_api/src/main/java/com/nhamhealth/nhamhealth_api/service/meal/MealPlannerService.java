package com.nhamhealth.nhamhealth_api.service.meal;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.request.MealPlanRequest;
import com.nhamhealth.nhamhealth_api.dto.request.MealPlanUpdateRequest;
import com.nhamhealth.nhamhealth_api.dto.response.MealPlanResponse;
import com.nhamhealth.nhamhealth_api.entity.MealPlan;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.repository.meal.MealPlanRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

@Service
public class MealPlannerService {
    private static final List<String> TYPES = List.of("BREAKFAST", "LUNCH", "DINNER", "SNACK");
    private static final List<String> STATUSES = List.of("PLANNED", "EATEN", "SKIPPED");
    private final MealPlanRepository plans;
    private final PlannerMealRepository plannerMeals;
    private final WeeklyMealRecommendationRepository recommendations;
    private final UserRepository users;

    public MealPlannerService(MealPlanRepository plans, PlannerMealRepository plannerMeals,
            WeeklyMealRecommendationRepository recommendations,
            UserRepository users) {
        this.plans = plans; this.plannerMeals = plannerMeals;
        this.recommendations = recommendations; this.users = users;
    }

    @Transactional(readOnly = true)
    public List<MealPlanResponse> week(Integer userId, LocalDate start, String lang) {
        LocalDate monday = start.minusDays(start.getDayOfWeek().getValue() - 1L);
        return plans.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(
                userId, monday, monday.plusDays(6)).stream().map(p -> response(p, lang)).toList();
    }

    @Transactional
    public MealPlanResponse addOrReplace(Integer userId, MealPlanRequest request, String lang) {
        String type = type(request.mealType());
        requireRecommendation(request.planDate(), type, request.plannerMealId());
        PlannerMeal meal = activePlannerMeal(request.plannerMealId());
        MealPlan plan = plans.findByUserUserIdAndPlanDateAndMealType(userId, request.planDate(), type)
                .orElseGet(() -> {
                    MealPlan value = new MealPlan();
                    value.setUser(users.getReferenceById(userId));
                    value.setPlanDate(request.planDate());
                    value.setMealType(type);
                    return value;
                });
        plan.setPlannerMeal(meal);
        plan.setServings(request.servings());
        plan.setStatus("PLANNED");
        plan.setCompletedAt(null);
        plan.setActualServings(null);
        return response(plans.save(plan), lang);
    }

    @Transactional
    public MealPlanResponse update(Integer userId, Integer id, MealPlanUpdateRequest request, String lang) {
        MealPlan plan = owned(id, userId);
        LocalDate targetDate = request.planDate() == null ? plan.getPlanDate() : request.planDate();
        Integer targetMealId = request.plannerMealId() == null
                ? plan.getPlannerMeal().getPlannerMealId() : request.plannerMealId();
        if (request.plannerMealId() != null || !targetDate.equals(plan.getPlanDate())) {
            requireRecommendation(targetDate, plan.getMealType(), targetMealId);
        }
        if (request.plannerMealId() != null) {
            plan.setPlannerMeal(activePlannerMeal(request.plannerMealId()));
            plan.setStatus("PLANNED");
            plan.setCompletedAt(null);
            plan.setActualServings(null);
        }
        if (request.servings() != null) plan.setServings(request.servings());
        if (request.status() != null) {
            String status = status(request.status());
            plan.setStatus(status);
            plan.setCompletedAt("EATEN".equals(status) ? LocalDateTime.now() : null);
            plan.setActualServings("EATEN".equals(status)
                    ? (request.actualServings() == null ? plan.getServings() : request.actualServings())
                    : null);
        } else if (request.actualServings() != null) {
            if (!"EATEN".equals(plan.getStatus())) {
                throw new ResponseStatusException(BAD_REQUEST, "Actual servings require EATEN status.");
            }
            plan.setActualServings(request.actualServings());
        }
        if (request.planDate() != null && !request.planDate().equals(plan.getPlanDate())) {
            var conflict = plans.findByUserUserIdAndPlanDateAndMealType(
                    userId, request.planDate(), plan.getMealType())
                    .filter(existing -> !existing.getMealPlanId().equals(id));
            if (conflict.isPresent()) {
                plans.delete(conflict.get());
                plans.flush();
            }
            plan.setPlanDate(request.planDate());
        }
        return response(plans.save(plan), lang);
    }

    @Transactional
    public void remove(Integer userId, Integer id) { plans.delete(owned(id, userId)); }

    private MealPlan owned(Integer id, Integer userId) {
        return plans.findByMealPlanIdAndUserUserId(id, userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Meal plan not found."));
    }
    private PlannerMeal activePlannerMeal(Integer id) {
        return plannerMeals.findById(id).filter(m -> Boolean.TRUE.equals(m.getActive()))
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Planner meal not found."));
    }
    private void requireRecommendation(LocalDate date, String type, Integer mealId) {
        if (!recommendations.existsByActiveTrueAndDayOfWeekInAndMealSlotAndPlannerMealPlannerMealIdAndPlannerMealActiveTrue(
                List.of("ALL", date.getDayOfWeek().name()), type, mealId)) {
            throw new ResponseStatusException(BAD_REQUEST,
                    "This meal is not an active admin recommendation for the selected day and slot.");
        }
    }
    private String type(String value) {
        String normalized = value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
        if (!TYPES.contains(normalized)) throw new ResponseStatusException(BAD_REQUEST, "Invalid meal type.");
        return normalized;
    }
    private String status(String value) {
        String normalized = value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
        if (!STATUSES.contains(normalized)) {
            throw new ResponseStatusException(BAD_REQUEST, "Invalid meal plan status.");
        }
        return normalized;
    }

    private MealPlanResponse response(MealPlan plan, String lang) {
        PlannerMeal detail = plan.getPlannerMeal();
        return new MealPlanResponse(plan.getMealPlanId(), plan.getPlanDate(), plan.getMealType(), plan.getServings(),
                plan.getStatus(), plan.getCompletedAt(), plan.getActualServings(),
                detail.getPlannerMealId(), detail.name(lang), detail.getCategory().getCategoryId(),
                detail.category(lang),
                detail.getImageUrl(), detail.getCalories(), detail.getProteinGrams(),
                detail.getCarbsGrams(), detail.getFatGrams(), detail.description(lang),
                detail.getCookingTimeMinutes(), "", PlannerMealContent.ingredients(detail, lang),
                PlannerMealContent.instructions(detail), PlannerMealContent.tags(detail));
    }
}
