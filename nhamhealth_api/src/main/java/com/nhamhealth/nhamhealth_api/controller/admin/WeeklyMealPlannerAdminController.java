package com.nhamhealth.nhamhealth_api.controller.admin;

import java.math.BigDecimal;
import java.time.DayOfWeek;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.multipart.MultipartFile;

import com.nhamhealth.nhamhealth_api.dto.request.PlannerMealRequest;
import com.nhamhealth.nhamhealth_api.dto.request.WeeklyMealRecommendationRequest;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealPlanRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;
import com.nhamhealth.nhamhealth_api.service.meal.PlannerMealIngredientBackfillService;
import com.nhamhealth.nhamhealth_api.service.meal.PlannerIngredientNormalizationService;

import jakarta.validation.Valid;

@Controller
public class WeeklyMealPlannerAdminController {
    private static final Set<String> WEIGHT_GOALS = Set.of(
            "LOSE_WEIGHT", "MAINTAIN_HEALTH", "GAIN_WEIGHT");
    private static final Set<String> SLOTS = Set.of("BREAKFAST", "LUNCH", "DINNER", "SNACK");
    private final WeeklyMealRecommendationRepository recommendations;
    private final PlannerMealRepository plannerMeals;
    private final MealPlanRepository mealPlans;
    private final MealCategoryRepository mealCategories;
    private final ProfileImageStorageService profileImageStorageService;
    private final PlannerMealIngredientBackfillService ingredientBackfillService;
    private final PlannerIngredientNormalizationService ingredientNormalizationService;

    public WeeklyMealPlannerAdminController(
            WeeklyMealRecommendationRepository recommendations,
            PlannerMealRepository plannerMeals,
            MealPlanRepository mealPlans,
            MealCategoryRepository mealCategories,
            ProfileImageStorageService profileImageStorageService,
            PlannerMealIngredientBackfillService ingredientBackfillService,
            PlannerIngredientNormalizationService ingredientNormalizationService) {
        this.recommendations = recommendations;
        this.plannerMeals = plannerMeals;
        this.mealPlans = mealPlans;
        this.mealCategories = mealCategories;
        this.profileImageStorageService = profileImageStorageService;
        this.ingredientBackfillService = ingredientBackfillService;
        this.ingredientNormalizationService = ingredientNormalizationService;
    }

    @GetMapping("/admin/meal-planner")
    @Transactional
    public String page(Authentication authentication, Model model) {
        removeMalformedUrlNamedMeals();
        List<WeeklyMealRecommendation> rows = recommendations
                .findAllByOrderBySortOrderAscRecommendationIdAsc()
                .stream().sorted(scheduleOrder()).toList();
        List<PlannerMeal> meals = plannerMeals.findAllByOrderByNameEnAsc();
        model.addAttribute("pageTitle", "Weekly Meal Planner");
        model.addAttribute("activePage", "meal-planner");
        model.addAttribute("adminName", authentication == null ? "Admin" : authentication.getName());
        model.addAttribute("recommendations", rows);
        model.addAttribute("plannerMeals", meals);
        model.addAttribute("mealCategories", mealCategories.findAllByIsActiveTrueOrderBySortOrderAsc());
        model.addAttribute("totalRecommendations", rows.size());
        model.addAttribute("activeRecommendations", rows.stream()
                .filter(row -> Boolean.TRUE.equals(row.getActive())
                        && Boolean.TRUE.equals(row.getPlannerMeal().getActive()))
                .count());
        List<WeeklyMealRecommendation> activeRows = rows.stream()
                .filter(row -> Boolean.TRUE.equals(row.getActive())
                        && Boolean.TRUE.equals(row.getPlannerMeal().getActive()))
                .toList();
        model.addAttribute("coveredDays", activeRows.stream()
                .anyMatch(row -> "ALL".equals(row.getDayOfWeek())) ? 7
                        : activeRows.stream().map(WeeklyMealRecommendation::getDayOfWeek).distinct().count());
        return "admin/meal-planner";
    }

    @PostMapping(value = "/admin/meal-planner/upload-image", consumes = "multipart/form-data")
    @ResponseBody
    public ResponseEntity<?> uploadImage(@RequestParam("file") MultipartFile file) {
        try {
            String url = profileImageStorageService.storeMealImage(file);
            return ResponseEntity.ok(Map.of("imageUrl", url, "mainImageUrl", url));
        } catch (IllegalArgumentException ex) {
            return bad(ex.getMessage());
        } catch (Exception ex) {
            return ResponseEntity.internalServerError()
                    .body(Map.of("message", "Image upload failed: " + ex.getMessage()));
        }
    }

    @PostMapping("/admin/meal-planner/meals")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> createMeal(@Valid @RequestBody PlannerMealRequest request, BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            String error = bindingResult.getFieldErrors().stream()
                    .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                    .collect(Collectors.joining(", "));
            return bad(error);
        }
        try {
            String error = validateMeal(request);
            if (error != null)
                return bad(error);
            PlannerMeal meal = new PlannerMeal();
            applyMeal(meal, request);
            meal = plannerMeals.save(meal);
            ingredientNormalizationService.sync(meal);
            createRecommendationsForEveryDay(meal);
            return ResponseEntity.ok(mealResponse(meal));
        } catch (Exception ex) {
            return bad("Failed to save meal: " + ex.getMessage());
        }
    }

    @PutMapping("/admin/meal-planner/meals/{id}")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> updateMeal(
            @PathVariable Integer id,
            @Valid @RequestBody PlannerMealRequest request,
            BindingResult bindingResult) {
        if (bindingResult.hasErrors()) {
            String error = bindingResult.getFieldErrors().stream()
                    .map(fe -> fe.getField() + ": " + fe.getDefaultMessage())
                    .collect(Collectors.joining(", "));
            return bad(error);
        }
        try {
            PlannerMeal meal = plannerMeals.findById(id).orElse(null);
            if (meal == null)
                return ResponseEntity.notFound().build();
            String error = validateMeal(request);
            if (error != null)
                return bad(error);
            applyMeal(meal, request);
            meal = plannerMeals.save(meal);
            ingredientNormalizationService.sync(meal);
            createRecommendationsForEveryDay(meal);
            return ResponseEntity.ok(mealResponse(meal));
        } catch (Exception ex) {
            return bad("Failed to update meal: " + ex.getMessage());
        }
    }

    @PostMapping("/admin/meal-planner/meals/backfill-ingredients")
    @ResponseBody
    public ResponseEntity<?> backfillMissingIngredients() {
        var result = ingredientBackfillService.backfillMissingIngredients();
        return ResponseEntity.ok(Map.of(
                "updated", result.updated(),
                "updatedCount", result.updated().size(),
                "skipped", result.skipped(),
                "failed", result.failed()));
    }

    @PostMapping("/admin/meal-planner/meals/normalize-ingredients")
    @ResponseBody
    public ResponseEntity<?> normalizeIngredients() {
        var result = ingredientNormalizationService.normalizeAll();
        return ResponseEntity.ok(Map.of(
                "mealsUpdated", result.mealsUpdated(),
                "ingredientRows", result.ingredientRows(),
                "ingredientsCreated", result.ingredientsCreated(),
                "skippedMeals", result.skippedMeals()));
    }

    @DeleteMapping("/admin/meal-planner/meals/{id}")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> deleteMeal(@PathVariable Integer id) {
        PlannerMeal meal = plannerMeals.findById(id).orElse(null);
        if (meal == null) {
            return ResponseEntity.notFound().build();
        }

        deletePermanently(meal);
        return ResponseEntity.ok(Map.of(
                "deleted", true,
                "archived", false,
                "message", "Planner meal and its saved plan entries were deleted permanently."));
    }

    private void removeMalformedUrlNamedMeals() {
        List<PlannerMeal> malformed = plannerMeals.findAllByOrderByNameEnAsc().stream()
                .filter(meal -> isUrl(meal.getNameEn()) || isUrl(meal.getNameKm()))
                .toList();
        malformed.forEach(this::deletePermanently);
    }

    private void deletePermanently(PlannerMeal meal) {
        Integer id = meal.getPlannerMealId();
        recommendations.deleteAllByPlannerMealPlannerMealId(id);
        mealPlans.deleteAllByPlannerMealPlannerMealId(id);
        plannerMeals.delete(meal);
    }

    private boolean isUrl(String value) {
        if (value == null)
            return false;
        String normalized = value.trim().toLowerCase(Locale.ROOT);
        return normalized.startsWith("http://") || normalized.startsWith("https://");
    }

    @PostMapping("/admin/meal-planner/recommendations")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> create(@RequestBody WeeklyMealRecommendationRequest request) {
        Validation validation = validate(request, null);
        if (validation.error() != null)
            return bad(validation.error());
        WeeklyMealRecommendation row = new WeeklyMealRecommendation();
        apply(row, request, validation.meal());
        row.setCreatedAt(LocalDateTime.now());
        return ResponseEntity.ok(toResponse(recommendations.save(row)));
    }

    @PostMapping("/admin/meal-planner/recommendations/bulk")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> createBulk(@RequestBody List<WeeklyMealRecommendationRequest> requests) {
        if (requests == null || requests.isEmpty())
            return bad("Select at least one weekday.");

        List<Validation> validations = requests.stream()
                .map(request -> validate(request, null))
                .toList();
        for (Validation validation : validations) {
            if (validation.error() != null)
                return bad(validation.error());
        }

        LocalDateTime now = LocalDateTime.now();
        List<Map<String, Object>> saved = new java.util.ArrayList<>();
        for (int index = 0; index < requests.size(); index++) {
            WeeklyMealRecommendation row = new WeeklyMealRecommendation();
            apply(row, requests.get(index), validations.get(index).meal());
            row.setCreatedAt(now);
            saved.add(toResponse(recommendations.save(row)));
        }
        return ResponseEntity.ok(saved);
    }

    @PutMapping("/admin/meal-planner/recommendations/{id}")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> update(@PathVariable Integer id,
            @RequestBody WeeklyMealRecommendationRequest request) {
        WeeklyMealRecommendation row = recommendations.findById(id).orElse(null);
        if (row == null)
            return ResponseEntity.notFound().build();
        Validation validation = validate(request, id);
        if (validation.error() != null)
            return bad(validation.error());
        apply(row, request, validation.meal());
        return ResponseEntity.ok(toResponse(recommendations.save(row)));
    }

    @DeleteMapping("/admin/meal-planner/recommendations/{id}")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> delete(@PathVariable Integer id) {
        WeeklyMealRecommendation recommendation = recommendations.findById(id).orElse(null);
        if (recommendation == null)
            return ResponseEntity.notFound().build();
        PlannerMeal meal = recommendation.getPlannerMeal();
        deletePermanently(meal);
        return ResponseEntity.ok(Map.of(
                "deleted", true,
                "message", "Planner meal and its saved plan entries were deleted permanently."));
    }

    private Validation validate(WeeklyMealRecommendationRequest request, Integer currentId) {
        if (request == null || request.plannerMealId() == null)
            return new Validation(null, "Select a planner meal.");
        PlannerMeal meal = plannerMeals.findById(request.plannerMealId()).orElse(null);
        if (meal == null || !Boolean.TRUE.equals(meal.getActive()))
            return new Validation(null, "Select an active planner meal.");
        String day = normalize(request.dayOfWeek());
        String slot = normalize(request.mealSlot());
        if (!"ALL".equals(day)) {
            try {
                DayOfWeek.valueOf(day);
            } catch (RuntimeException ex) {
                return new Validation(null, "Select a valid weekday.");
            }
        }
        if (!SLOTS.contains(slot))
            return new Validation(null, "Select a valid meal slot.");
        boolean duplicate = currentId == null
                ? recommendations.existsByDayOfWeekAndMealSlotAndPlannerMealPlannerMealId(day, slot,
                        meal.getPlannerMealId())
                : recommendations.existsByDayOfWeekAndMealSlotAndPlannerMealPlannerMealIdAndRecommendationIdNot(
                        day, slot, meal.getPlannerMealId(), currentId);
        return duplicate ? new Validation(null, "This meal is already recommended for that day and slot.")
                : new Validation(meal, null);
    }

    private void apply(WeeklyMealRecommendation row, WeeklyMealRecommendationRequest request, PlannerMeal meal) {
        row.setPlannerMeal(meal);
        row.setMeal(null);
        row.setDayOfWeek(normalize(request.dayOfWeek()));
        row.setMealSlot(normalize(request.mealSlot()));
        row.setNote(clean(request.note()));
        row.setActive(request.active() == null || request.active());
        row.setSortOrder(request.sortOrder() == null ? 0 : Math.max(0, request.sortOrder()));
        row.setUpdatedAt(LocalDateTime.now());
    }

    private String validateMeal(PlannerMealRequest request) {
        if (request == null || request.nameEn() == null || request.nameEn().isBlank())
            return "Enter an English meal name.";
        List<Integer> catIds = request.categoryIds() != null && !request.categoryIds().isEmpty()
                ? request.categoryIds()
                : (request.categoryId() != null ? List.of(request.categoryId()) : List.of());
        if (catIds.isEmpty())
            return "Select at least one active meal category.";
        for (Integer cid : catIds) {
            MealCategory category = mealCategories.findById(cid).orElse(null);
            if (category == null || !Boolean.TRUE.equals(category.getIsActive())) {
                return "Select active meal categories.";
            }
        }
        if (request.nameEn().trim().length() > 150)
            return "Meal name is too long.";
        if (request.calories() == null || request.proteinGrams() == null
                || request.carbsGrams() == null || request.fatGrams() == null
                || request.calories().signum() < 0 || request.proteinGrams().signum() < 0
                || request.carbsGrams().signum() < 0 || request.fatGrams().signum() < 0)
            return "Enter non-negative nutrition values.";
        if (request.cookingTimeMinutes() != null && request.cookingTimeMinutes() < 0)
            return "Cooking time cannot be negative.";
        if (request.weightGoals() != null && request.weightGoals().stream()
                .map(this::normalize)
                .anyMatch(goal -> !WEIGHT_GOALS.contains(goal))) {
            return "Select valid weight goals.";
        }
        return null;
    }

    private void applyMeal(PlannerMeal meal, PlannerMealRequest request) {
        List<Integer> catIds = request.categoryIds() != null && !request.categoryIds().isEmpty()
                ? request.categoryIds()
                : (request.categoryId() != null ? List.of(request.categoryId()) : List.of());
        List<MealCategory> selectedCats = catIds.stream()
                .map(id -> mealCategories.findById(id).orElse(null))
                .filter(Objects::nonNull)
                .toList();
        if (selectedCats.isEmpty()) {
            throw new IllegalArgumentException("No valid categories provided.");
        }
        MealCategory primaryCategory = selectedCats.getFirst();
        meal.setNameEn(request.nameEn().trim());
        meal.setNameKm(clean(request.nameKm()));
        meal.setCategory(primaryCategory);
        meal.setCategories(new HashSet<>(selectedCats));
        meal.setCategoryEn(selectedCats.stream().map(MealCategory::getCategoryName).collect(Collectors.joining(", ")));
        meal.setCategoryKm(null);
        meal.setDescriptionEn(clean(request.descriptionEn()));
        meal.setDescriptionKm(clean(request.descriptionKm()));
        meal.setImageUrl(clean(request.imageUrl()));
        meal.setCalories(request.calories() == null ? BigDecimal.ZERO : request.calories());
        meal.setProteinGrams(request.proteinGrams() == null ? BigDecimal.ZERO : request.proteinGrams());
        meal.setCarbsGrams(request.carbsGrams() == null ? BigDecimal.ZERO : request.carbsGrams());
        meal.setFatGrams(request.fatGrams() == null ? BigDecimal.ZERO : request.fatGrams());
        meal.setCookingTimeMinutes(request.cookingTimeMinutes());
        meal.setIngredientsText(clean(request.ingredientsText()));
        meal.setIngredientsTextKm(clean(request.ingredientsTextKm()));
        meal.setInstructionsText(clean(request.instructionsText()));
        meal.setInstructionsTextKm(clean(request.instructionsTextKm()));
        meal.setTagsText(clean(request.tagsText()));
        meal.setTagsTextKm(clean(request.tagsTextKm()));
        Set<String> selectedGoals = request.weightGoals() == null || request.weightGoals().isEmpty()
                ? WEIGHT_GOALS
                : request.weightGoals().stream()
                        .map(this::normalize)
                        .filter(WEIGHT_GOALS::contains)
                        .collect(Collectors.toSet());
        meal.setWeightGoals(selectedGoals);
        meal.setActive(request.active() == null || request.active());
    }

    private void createRecommendationsForEveryDay(PlannerMeal meal) {
        Set<String> slots = new HashSet<>();
        if (meal.getCategories() != null && !meal.getCategories().isEmpty()) {
            for (MealCategory cat : meal.getCategories()) {
                slots.add(slotForCategory(cat.getCategoryName()));
            }
        } else if (meal.getCategory() != null) {
            slots.add(slotForCategory(meal.getCategory().getCategoryName()));
        } else {
            slots.add("LUNCH");
        }

        LocalDateTime now = LocalDateTime.now();
        for (String slot : slots) {
            if (!recommendations.existsByDayOfWeekAndMealSlotAndPlannerMealPlannerMealId("ALL", slot,
                    meal.getPlannerMealId())) {
                WeeklyMealRecommendation row = new WeeklyMealRecommendation();
                row.setPlannerMeal(meal);
                row.setMeal(null);
                row.setDayOfWeek("ALL");
                row.setMealSlot(slot);
                row.setActive(Boolean.TRUE.equals(meal.getActive()));
                row.setSortOrder(0);
                row.setCreatedAt(now);
                row.setUpdatedAt(now);
                recommendations.save(row);
            }
        }
    }

    private String slotForCategory(String categoryName) {
        String value = categoryName == null ? "" : categoryName.toUpperCase(Locale.ROOT);
        if (value.contains("BREAKFAST"))
            return "BREAKFAST";
        if (value.contains("DINNER"))
            return "DINNER";
        if (value.contains("SNACK") || value.contains("DESSERT"))
            return "SNACK";
        return "LUNCH";
    }

    private Map<String, Object> mealResponse(PlannerMeal meal) {
        List<Integer> categoryIds = meal.getCategories() != null && !meal.getCategories().isEmpty()
                ? meal.getCategories().stream().map(MealCategory::getCategoryId).toList()
                : (meal.getCategory() != null ? List.of(meal.getCategory().getCategoryId()) : List.of());
        List<String> categoryNames = meal.getCategories() != null && !meal.getCategories().isEmpty()
                ? meal.getCategories().stream().map(MealCategory::getCategoryName).toList()
                : (meal.getCategory() != null ? List.of(meal.getCategory().getCategoryName()) : List.of());
        return Map.of(
                "id", meal.getPlannerMealId(),
                "name", meal.getNameEn(),
                "categoryId", meal.getCategory().getCategoryId(),
                "categoryName", meal.getCategory().getCategoryName(),
                "categoryIds", categoryIds,
                "categoryNames", categoryNames,
                "weightGoals", meal.getWeightGoals().stream().sorted().toList(),
                "calories", meal.getCalories(),
                "active", Boolean.TRUE.equals(meal.getActive()));
    }

    private Map<String, Object> toResponse(WeeklyMealRecommendation row) {
        return Map.ofEntries(
                Map.entry("id", row.getRecommendationId()),
                Map.entry("plannerMealId", row.getPlannerMeal().getPlannerMealId()),
                Map.entry("mealName", row.getPlannerMeal().getNameEn()),
                Map.entry("dayOfWeek", row.getDayOfWeek()),
                Map.entry("mealSlot", row.getMealSlot()),
                Map.entry("note", row.getNote() == null ? "" : row.getNote()),
                Map.entry("active", Boolean.TRUE.equals(row.getActive())),
                Map.entry("sortOrder", row.getSortOrder()));
    }

    private Comparator<WeeklyMealRecommendation> scheduleOrder() {
        return Comparator
                .comparingInt((WeeklyMealRecommendation row) -> "ALL".equals(row.getDayOfWeek()) ? 0
                        : DayOfWeek.valueOf(row.getDayOfWeek()).getValue())
                .thenComparingInt(row -> List.of("BREAKFAST", "LUNCH", "DINNER", "SNACK").indexOf(row.getMealSlot()))
                .thenComparing(WeeklyMealRecommendation::getSortOrder)
                .thenComparing(WeeklyMealRecommendation::getRecommendationId);
    }

    private ResponseEntity<Map<String, String>> bad(String message) {
        return ResponseEntity.badRequest().body(Map.of("message", message));
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toUpperCase();
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private record Validation(PlannerMeal meal, String error) {
    }
}
