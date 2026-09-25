package com.nhamhealth.nhamhealth_api.service.meal;

import static org.springframework.http.HttpStatus.BAD_REQUEST;
import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashSet;
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
import com.nhamhealth.nhamhealth_api.service.wellness.DailyNutritionService;

@Service
public class MealPlannerService {
    private static final List<String> TYPES = List.of("BREAKFAST", "LUNCH", "DINNER", "SNACK");
    private static final List<String> STATUSES = List.of("PLANNED", "EATEN", "SKIPPED");
    private static final List<String> WEIGHT_GOALS = List.of("LOSE_WEIGHT", "MAINTAIN_HEALTH", "GAIN_WEIGHT");
    private final MealPlanRepository plans;
    private final PlannerMealRepository plannerMeals;
    private final WeeklyMealRecommendationRepository recommendations;
    private final UserRepository users;
    private final DailyNutritionService dailyNutrition;

    public MealPlannerService(MealPlanRepository plans, PlannerMealRepository plannerMeals,
            WeeklyMealRecommendationRepository recommendations,
            UserRepository users,
            DailyNutritionService dailyNutrition) {
        this.plans = plans;
        this.plannerMeals = plannerMeals;
        this.recommendations = recommendations;
        this.users = users;
        this.dailyNutrition = dailyNutrition;
    }

    @Transactional(readOnly = true)
    public List<MealPlanResponse> range(Integer userId, LocalDate start, LocalDate end, String lang) {
        LocalDate effectiveStart = start != null ? start : LocalDate.now();
        LocalDate effectiveEnd = end != null ? end : effectiveStart.plusDays(6);
        if (effectiveEnd.isBefore(effectiveStart)) {
            LocalDate tmp = effectiveStart;
            effectiveStart = effectiveEnd;
            effectiveEnd = tmp;
        }
        return plans.findAllByUserUserIdAndPlanDateBetweenOrderByPlanDateAscMealTypeAsc(
                userId, effectiveStart, effectiveEnd).stream().map(p -> response(p, lang)).toList();
    }

    @Transactional(readOnly = true)
    public List<MealPlanResponse> day(Integer userId, LocalDate date, String lang) {
        LocalDate target = date != null ? date : LocalDate.now();
        return range(userId, target, target, lang);
    }

    @Transactional(readOnly = true)
    public List<MealPlanResponse> week(Integer userId, LocalDate start, String lang) {
        LocalDate monday = start.minusDays(start.getDayOfWeek().getValue() - 1L);
        return range(userId, monday, monday.plusDays(6), lang);
    }

    @Transactional
    public MealPlanResponse addOrReplace(Integer userId, MealPlanRequest request, String lang) {
        String type = type(request.mealType());
        PlannerMeal meal = activePlannerMeal(request.plannerMealId());
        requireGoalCompatible(meal, request.weightGoal());
        MealPlan plan = plans.findByUserUserIdAndPlanDateAndMealType(userId, request.planDate(), type)
                .orElseGet(() -> {
                    MealPlan value = new MealPlan();
                    value.setUser(users.getReferenceById(userId));
                    value.setPlanDate(request.planDate());
                    value.setMealType(type);
                    return value;
                });
        boolean wasEaten = "EATEN".equals(plan.getStatus());
        plan.setPlannerMeal(meal);
        plan.setServings(request.servings());
        plan.setStatus("PLANNED");
        plan.setCompletedAt(null);
        plan.setActualServings(null);
        MealPlan saved = plans.save(plan);
        if (wasEaten) dailyNutrition.removeMealPlan(userId, saved.getMealPlanId());
        return response(saved, lang);
    }

    @Transactional
    public List<MealPlanResponse> bulkAddOrReplace(Integer userId, List<MealPlanRequest> requests, String lang) {
        if (requests == null || requests.isEmpty()) {
            return List.of();
        }
        List<MealPlanResponse> results = new ArrayList<>(requests.size());
        for (MealPlanRequest request : requests) {
            results.add(addOrReplace(userId, request, lang));
            plans.flush();
        }
        return results;
    }

    @Transactional
    public MealPlanResponse update(Integer userId, Integer id, MealPlanUpdateRequest request, String lang) {
        MealPlan plan = owned(id, userId);
        if (request.plannerMealId() != null) {
            PlannerMeal replacement = activePlannerMeal(request.plannerMealId());
            requireGoalCompatible(replacement, request.weightGoal());
            plan.setPlannerMeal(replacement);
            plan.setStatus("PLANNED");
            plan.setCompletedAt(null);
            plan.setActualServings(null);
        }
        if (request.servings() != null) {
            plan.setServings(request.servings());
        }
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
                dailyNutrition.removeMealPlan(userId, conflict.get().getMealPlanId());
                plans.delete(conflict.get());
                plans.flush();
            }
            plan.setPlanDate(request.planDate());
        }
        MealPlan saved = plans.save(plan);
        syncNutrition(userId, saved);
        return response(saved, lang);
    }

    private void requireGoalCompatible(PlannerMeal meal, String requestedGoal) {
        if (requestedGoal == null || requestedGoal.isBlank()) {
            throw new ResponseStatusException(BAD_REQUEST, "Select a weight goal.");
        }
        String goal = requestedGoal.trim().toUpperCase(Locale.ROOT);
        if (!WEIGHT_GOALS.contains(goal)) {
            throw new ResponseStatusException(BAD_REQUEST, "Select a valid weight goal.");
        }
        if (!meal.supportsWeightGoal(goal)) {
            throw new ResponseStatusException(BAD_REQUEST,
                    "This meal is not available for the selected weight goal.");
        }
    }

    @Transactional
    public void remove(Integer userId, Integer id) {
        MealPlan plan = owned(id, userId);
        dailyNutrition.removeMealPlan(userId, plan.getMealPlanId());
        plans.delete(plan);
    }

    @Transactional
    public List<MealPlanResponse> updateStatusBulk(
            Integer userId,
            List<Integer> ids,
            String requestedStatus,
            String lang) {
        String normalizedStatus = status(requestedStatus);
        List<MealPlan> ownedPlans = distinctOwned(ids, userId);
        LocalDateTime completedAt = "EATEN".equals(normalizedStatus) ? LocalDateTime.now() : null;
        for (MealPlan plan : ownedPlans) {
            plan.setStatus(normalizedStatus);
            plan.setCompletedAt(completedAt);
            plan.setActualServings("EATEN".equals(normalizedStatus) ? plan.getServings() : null);
            syncNutrition(userId, plan);
        }
        return plans.saveAll(ownedPlans).stream().map(plan -> response(plan, lang)).toList();
    }

    @Transactional
    public void removeBulk(Integer userId, List<Integer> ids) {
        // Resolve every ID before deleting any row. A missing or foreign ID
        // therefore rolls back the whole request instead of partially clearing.
        List<MealPlan> ownedPlans = distinctOwned(ids, userId);
        ownedPlans.forEach(plan -> dailyNutrition.removeMealPlan(userId, plan.getMealPlanId()));
        plans.deleteAll(ownedPlans);
    }

    private void syncNutrition(Integer userId, MealPlan plan) {
        if (!"EATEN".equals(plan.getStatus())) {
            dailyNutrition.removeMealPlan(userId, plan.getMealPlanId());
            return;
        }
        PlannerMeal meal = plan.getPlannerMeal();
        var servings = plan.getActualServings() == null ? plan.getServings() : plan.getActualServings();
        dailyNutrition.upsertMealPlan(userId, plan.getMealPlanId(), plan.getPlanDate(),
                meal.getCalories().multiply(servings),
                meal.getProteinGrams().multiply(servings),
                meal.getCarbsGrams().multiply(servings),
                meal.getFatGrams().multiply(servings));
    }

    private List<MealPlan> distinctOwned(List<Integer> ids, Integer userId) {
        if (ids == null || ids.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "At least one meal plan is required.");
        }
        return new LinkedHashSet<>(ids).stream()
                .map(id -> owned(id, userId))
                .toList();
    }

    private MealPlan owned(Integer id, Integer userId) {
        return plans.findByMealPlanIdAndUserUserId(id, userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Meal plan not found."));
    }

    private PlannerMeal activePlannerMeal(Integer id) {
        return plannerMeals.findById(id).filter(m -> Boolean.TRUE.equals(m.getActive()))
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Planner meal not found."));
    }

    private String type(String value) {
        String normalized = value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
        if (!TYPES.contains(normalized)) {
            throw new ResponseStatusException(BAD_REQUEST, "Invalid meal type.");
        }
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
                PlannerMealContent.instructions(detail, lang), PlannerMealContent.tags(detail, lang));
    }
}
