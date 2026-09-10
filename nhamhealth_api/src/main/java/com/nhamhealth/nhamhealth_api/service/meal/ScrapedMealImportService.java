package com.nhamhealth.nhamhealth_api.service.meal;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.net.URI;
import java.time.OffsetDateTime;
import java.util.*;
import java.util.stream.Collectors;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.request.*;
import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.repository.catalog.*;
import com.nhamhealth.nhamhealth_api.repository.meal.*;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;
import jakarta.persistence.EntityManager;
import jakarta.validation.Validator;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ScrapedMealImportService {
    private final ObjectMapper json = new ObjectMapper();
    private final Validator validator;
    private final MealCategoryRepository categories;
    private final IngredientRepository ingredients;
    private final NutrientRepository nutrients;
    private final MealNutritionRepository nutrition;
    private final MealRepository meals;
    private final MealAdminService admin;
    private final ProfileImageStorageService images;
    private final EntityManager em;

    public ScrapedMealImportService(Validator validator, MealCategoryRepository categories,
            IngredientRepository ingredients, NutrientRepository nutrients,
            MealNutritionRepository nutrition, MealRepository meals, MealAdminService admin,
            ProfileImageStorageService images, EntityManager em) {
        this.validator = validator;
        this.categories = categories;
        this.ingredients = ingredients;
        this.nutrients = nutrients;
        this.nutrition = nutrition;
        this.meals = meals;
        this.admin = admin;
        this.images = images;
        this.em = em;
    }

    @Transactional
    public Map<String, Object> importMeal(String payload, MultipartFile image) {
        ScrapedMealImportRequest request;
        if (payload == null || payload.length() > 500_000) {
            throw new IllegalArgumentException("Recipe JSON is missing or too large");
        }
        try {
            request = json.readValue(payload, ScrapedMealImportRequest.class);
        } catch (JsonProcessingException exception) {
            throw new IllegalArgumentException("Recipe must be valid import JSON");
        }
        if (request == null) throw new IllegalArgumentException("Recipe is required");
        var violations = validator.validate(request);
        if (!violations.isEmpty()) {
            throw new IllegalArgumentException(violations.stream()
                    .map(v -> v.getPropertyPath() + ": " + v.getMessage()).sorted().collect(Collectors.joining("; ")));
        }
        String sourceUrl = canonicalSourceUrl(request.sourceUrl());
        try {
            OffsetDateTime.parse(request.scrapedAt());
        } catch (java.time.format.DateTimeParseException exception) {
            throw new IllegalArgumentException("scrapedAt must be an ISO timestamp with timezone");
        }
        if (image != null && (image.isEmpty() || image.getSize() > 5 * 1024 * 1024)) {
            throw new IllegalArgumentException("Provided meal image must be non-empty and at most 5 MB");
        }

        // Serialize imports so concurrent retries cannot create duplicate meals.
        // This lock is scoped to the PostgreSQL transaction, not the application process.
        em.createNativeQuery("SELECT 1 FROM pg_advisory_xact_lock(781420091)").getSingleResult();
        if (!em.createNativeQuery("SELECT meal_id FROM scraped_meal_sources WHERE source_url = :url")
                .setParameter("url", sourceUrl).getResultList().isEmpty()
                || !em.createQuery("select m.mealId from Meal m where lower(trim(m.mealName)) = :name")
                .setParameter("name", request.mealName().trim().toLowerCase(Locale.ROOT)).getResultList().isEmpty()) {
            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.CONFLICT, "This source URL or meal name is already imported");
        }
        var category = categories.findByCategoryNameIgnoreCase(request.categoryName().trim())
                .filter(c -> Boolean.TRUE.equals(c.getIsActive()))
                .orElseThrow(() -> new IllegalArgumentException("Unknown or inactive category: " + request.categoryName()));
        List<String> warnings = new ArrayList<>();
        Map<String, Ingredient> catalogByName = new HashMap<>();
        Map<Integer, AdminMealIngredientRequest> resolvedById = new LinkedHashMap<>();
        var orderedIngredients = request.ingredients().stream()
                .sorted(Comparator.comparing(ScrapedMealImportRequest.IngredientInput::displayOrder)).toList();
        for (int i = 0; i < orderedIngredients.size(); i++) {
            var item = orderedIngredients.get(i);
            if (item.displayOrder() != i + 1) throw new IllegalArgumentException("Ingredient displayOrder must be consecutive from 1");
            String ingredientName = item.ingredientName().trim();
            String normalizedName = ingredientName.toLowerCase(Locale.ROOT);
            Ingredient ingredient = catalogByName.computeIfAbsent(normalizedName, ignored ->
                    ingredients.findByIngredientNameIgnoreCase(ingredientName)
                            .orElseGet(() -> createScrapedIngredient(
                                    ingredientName, item.unit(), request.sourceName(), warnings)));
            AdminMealIngredientRequest incoming = new AdminMealIngredientRequest(
                    ingredient.getIngredientId(), item.quantity(), item.unit(), item.preparationNote(),
                    item.ingredientNameKm(), item.preparationNoteKm());
            resolvedById.merge(ingredient.getIngredientId(), incoming,
                    (existing, repeated) -> mergeRepeatedIngredient(existing, repeated, ingredientName, warnings));
        }
        List<AdminMealIngredientRequest> resolved = new ArrayList<>(resolvedById.values());
        var orderedSteps = request.steps().stream()
                .sorted(Comparator.comparing(ScrapedMealImportRequest.StepInput::stepNumber)).toList();
        for (int i = 0; i < orderedSteps.size(); i++) {
            if (orderedSteps.get(i).stepNumber() != i + 1) throw new IllegalArgumentException("Step numbers must be consecutive from 1");
        }

        Map<Nutrient, BigDecimal> amounts = new LinkedHashMap<>();
        addNutrient(amounts, "Protein", request.proteinGrams(), request, warnings);
        addNutrient(amounts, "Carbohydrates", request.carbohydrateGrams(), request, warnings);
        addNutrient(amounts, "Fat", request.fatGrams(), request, warnings);
        BigDecimal calories = perServing(request.calories(), request);
        if ((request.calories() != null || request.proteinGrams() != null || request.carbohydrateGrams() != null
                || request.fatGrams() != null) && Set.of("UNKNOWN", "PER_100G").contains(request.nutritionBasis())) {
            warnings.add("Nutrition retained in source payload only: per-serving basis cannot be determined");
        }
        String imageUrl = image == null ? null : images.storeMealImage(image);
        if (imageUrl == null) warnings.add("Draft has no image; upload a meal photo in Admin before publishing");
        var saved = admin.createScrapedDraft(new AdminMealRequest(request.mealName(), request.khmerName(), category.getCategoryId(),
                calories, request.servings(), request.description(), request.descriptionKm(), request.difficulty(), request.cookingTimeMinutes(),
                false, imageUrl, resolved, orderedSteps.stream().map(s -> new AdminRecipeStepRequest(s.instruction(), s.instructionKm())).toList()));
        Meal meal = meals.findById(saved.mealId()).orElseThrow();
        meal.setProteinGramsCached(perServing(request.proteinGrams(), request));
        for (var entry : amounts.entrySet()) {
            MealNutrition row = new MealNutrition();
            row.setMeal(meal);
            row.setNutrient(entry.getKey());
            row.setAmountPerServing(entry.getValue());
            nutrition.save(row);
        }
        em.createNativeQuery("INSERT INTO scraped_meal_sources (meal_id, source_url, source_payload, review_status) "
                + "VALUES (:id, :url, :payload, 'PENDING_REVIEW')")
                .setParameter("id", saved.mealId()).setParameter("url", sourceUrl).setParameter("payload", payload).executeUpdate();
        Map<String, Object> response = new LinkedHashMap<>(Map.of("mealId", saved.mealId(), "mealName", saved.mealName(),
                "published", false, "reviewStatus", "PENDING_REVIEW", "warnings", warnings));
        response.put("mainImageUrl", imageUrl);
        return response;
    }

    private Ingredient createScrapedIngredient(String name, String unit, String sourceName, List<String> warnings) {
        Ingredient ingredient = new Ingredient();
        ingredient.setIngredientName(name);
        ingredient.setIngredientType("SCRAPED_PENDING_REVIEW");
        ingredient.setDefaultUnit(unit == null || unit.isBlank() ? null : unit.trim());
        ingredient.setDescription("Auto-created from reviewed scraped recipe source: " + sourceName.trim());
        Ingredient saved = ingredients.save(ingredient);
        warnings.add("Created ingredient catalog entry pending review: " + name);
        return saved;
    }

    private AdminMealIngredientRequest mergeRepeatedIngredient(
            AdminMealIngredientRequest existing,
            AdminMealIngredientRequest repeated,
            String name,
            List<String> warnings) {
        String existingUnit = clean(existing.unit());
        String repeatedUnit = clean(repeated.unit());
        BigDecimal quantity = null;
        String unit = null;
        String note;

        if (Objects.equals(existingUnit == null ? null : existingUnit.toLowerCase(Locale.ROOT),
                repeatedUnit == null ? null : repeatedUnit.toLowerCase(Locale.ROOT))
                && existing.quantity() != null && repeated.quantity() != null) {
            quantity = existing.quantity().add(repeated.quantity());
            unit = existingUnit;
            note = joinNotes(existing.preparationNote(), repeated.preparationNote());
        } else {
            note = joinNotes(describeAmount(existing), describeAmount(repeated));
        }

        warnings.add("Combined repeated ingredient lines: " + name);
        String khmerName = existing.ingredientNameKm() != null ? existing.ingredientNameKm() : repeated.ingredientNameKm();
        String khmerNote = joinNotes(existing.preparationNoteKm(), repeated.preparationNoteKm());
        return new AdminMealIngredientRequest(existing.ingredientId(), quantity, unit, note, khmerName, khmerNote);
    }

    private String describeAmount(AdminMealIngredientRequest item) {
        List<String> parts = new ArrayList<>();
        if (item.quantity() != null) parts.add(item.quantity().stripTrailingZeros().toPlainString());
        if (clean(item.unit()) != null) parts.add(clean(item.unit()));
        if (clean(item.preparationNote()) != null) parts.add(clean(item.preparationNote()));
        return parts.isEmpty() ? "additional amount" : String.join(" ", parts);
    }

    private String joinNotes(String first, String second) {
        String left = clean(first);
        String right = clean(second);
        String joined = left == null ? right : right == null ? left : left.equalsIgnoreCase(right) ? left : left + "; " + right;
        return joined == null || joined.length() <= 150 ? joined : joined.substring(0, 150);
    }

    private String clean(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private void addNutrient(Map<Nutrient, BigDecimal> amounts, String name, BigDecimal value,
            ScrapedMealImportRequest request, List<String> warnings) {
        BigDecimal amount = perServing(value, request);
        if (amount == null) return;
        var nutrient = nutrients.findByNutrientNameIgnoreCase(name).filter(n -> "g".equalsIgnoreCase(n.getUnit()));
        if (nutrient.isPresent()) amounts.put(nutrient.get(), amount);
        else warnings.add(name + " retained in source payload; add a nutrient catalog entry with unit g");
    }

    static BigDecimal perServing(BigDecimal value, ScrapedMealImportRequest request) {
        if (value == null) return null;
        return switch (request.nutritionBasis()) {
            case "PER_SERVING" -> value;
            case "WHOLE_RECIPE" -> value.divide(BigDecimal.valueOf(request.servings()), 4, RoundingMode.HALF_UP);
            default -> null;
        };
    }

    static String canonicalSourceUrl(String value) {
        try {
            URI uri = URI.create(value.trim());
            if (!Set.of("https", "http").contains(uri.getScheme()) || uri.getHost() == null || uri.getUserInfo() != null) {
                throw new IllegalArgumentException();
            }
            String path = uri.normalize().getPath().replaceAll("/+$", "");
            return new URI(uri.getScheme().toLowerCase(Locale.ROOT), null, uri.getHost().toLowerCase(Locale.ROOT),
                    uri.getPort(), path, uri.getQuery(), null).toString();
        } catch (Exception exception) {
            throw new IllegalArgumentException("sourceUrl must be an absolute HTTP(S) URL");
        }
    }
}
