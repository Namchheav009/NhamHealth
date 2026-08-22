package com.nhamhealth.nhamhealth_api.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.LocalDate;
import java.time.Period;
import java.math.RoundingMode;
import java.util.List;
import java.util.Locale;
import java.util.Comparator;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;
import com.nhamhealth.nhamhealth_api.dto.request.AiFoodFeedbackRequest;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysisNutrient;
import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisNutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.NutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.FoodNutritionRepository;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.WellnessProfileRepository;
import org.springframework.web.server.ResponseStatusException;
import static org.springframework.http.HttpStatus.NOT_FOUND;

@Service
public class AiFoodAnalysisService {
    private final NvidiaFoodVisionService visionService;
    private final UserRepository userRepository;
    private final AiFoodAnalysisRepository analysisRepository;
    private final AiFoodAnalysisNutrientRepository analysisNutrientRepository;
    private final NutrientRepository nutrientRepository;
    private final FoodNutritionRepository foodNutritionRepository;
    private final UserProfileRepository userProfileRepository;
    private final WellnessProfileRepository wellnessProfileRepository;

    public AiFoodAnalysisService(
            NvidiaFoodVisionService visionService,
            UserRepository userRepository,
            AiFoodAnalysisRepository analysisRepository,
            AiFoodAnalysisNutrientRepository analysisNutrientRepository,
            NutrientRepository nutrientRepository,
            FoodNutritionRepository foodNutritionRepository,
            UserProfileRepository userProfileRepository,
            WellnessProfileRepository wellnessProfileRepository) {
        this.visionService = visionService;
        this.userRepository = userRepository;
        this.analysisRepository = analysisRepository;
        this.analysisNutrientRepository = analysisNutrientRepository;
        this.nutrientRepository = nutrientRepository;
        this.foodNutritionRepository = foodNutritionRepository;
        this.userProfileRepository = userProfileRepository;
        this.wellnessProfileRepository = wellnessProfileRepository;
    }

    @Transactional
    public AiFoodAnalysisResponse analyzeAndSave(
            Integer userId, String fileName, byte[] image, String contentType) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        List<FoodNutrition> activeFoods = foodNutritionRepository.findAllByActiveTrue();
        UserNutritionContext userContext = loadUserContext(userId);
        AiFoodModelResult modelResult = visionService.analyze(
                image, contentType, userContext, buildFoodCatalog(activeFoods));
        AiFoodAnalysisResponse result = enrichWithDatabase(modelResult.response(), activeFoods);

        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setUser(user);
        analysis.setInputText(fileName == null || fileName.isBlank() ? "Food image" : fileName);
        analysis.setDetectedFoodName(result.name());
        analysis.setAnalysisText(result.analysis());
        analysis.setDetectedServingText(formatServing(result.servingSize(), result.servingUnit()));
        analysis.setConfidenceScore(BigDecimal.valueOf(result.confidence()));
        analysis.setStatus(result.needsUserConfirmation() ? "REVIEW" : "COMPLETED");
        analysis.setCreatedAt(LocalDateTime.now());
        analysis.setModelName(modelResult.modelName());
        analysis.setPromptVersion(modelResult.promptVersion());
        analysis.setDatabaseMatched(result.databaseMatched());
        analysis.setNutritionFallbackUsed(modelResult.nutritionFallbackUsed());
        analysis.setPromptTokens(modelResult.promptTokens());
        analysis.setCompletionTokens(modelResult.completionTokens());
        analysis.setLatencyMs(modelResult.latencyMs());
        analysisRepository.saveAndFlush(analysis);

        saveNutrient(analysis, "Calories", "kcal", 1, result.calories());
        saveNutrient(analysis, "Protein", "g", 2, result.protein());
        saveNutrient(analysis, "Carbs", "g", 3, result.carbs());
        saveNutrient(analysis, "Fat", "g", 4, result.fat());
        saveNutrient(analysis, "Sugar", "g", 5, result.sugar());
        return result.withAnalysisId(analysis.getAiFoodAnalysisId());
    }

    private UserNutritionContext loadUserContext(Integer userId) {
        var wellness = wellnessProfileRepository.findByUser_UserId(userId).orElse(null);
        var profile = userProfileRepository.findByUser_UserId(userId).orElse(null);
        Integer age = profile != null && profile.getDateOfBirth() != null
                ? Period.between(profile.getDateOfBirth(), LocalDate.now()).getYears()
                : wellness != null && wellness.getAgeCached() != null
                        ? wellness.getAgeCached().intValue() : null;
        BigDecimal height = wellness == null ? null : wellness.getHeightCm();
        BigDecimal weight = wellness == null ? null : wellness.getWeightKg();
        BigDecimal bmi = null;
        if (height != null && weight != null && height.signum() > 0) {
            BigDecimal heightMeters = height.movePointLeft(2);
            bmi = weight.divide(heightMeters.multiply(heightMeters), 1, RoundingMode.HALF_UP);
        }
        return new UserNutritionContext(age, height, weight, bmi,
                wellness == null ? null : wellness.getActivityLevel());
    }

    private String buildFoodCatalog(List<FoodNutrition> foods) {
        return foods.stream()
                .sorted(Comparator.comparing((FoodNutrition food) -> !isCambodianFood(food))
                        .thenComparing(FoodNutrition::getName, String.CASE_INSENSITIVE_ORDER))
                .limit(150)
                .map(this::formatCatalogFood)
                .reduce((left, right) -> left + "\n" + right)
                .orElse("No database foods available");
    }

    private boolean isCambodianFood(FoodNutrition food) {
        String searchable = normalize(food.getName() + " "
                + (food.getAliases() == null ? "" : food.getAliases()));
        return searchable.matches(".*[\u1780-\u17ff].*")
                || searchable.contains("khmer") || searchable.contains("cambodian")
                || searchable.contains("samlor") || searchable.contains("somlor");
    }

    private String formatCatalogFood(FoodNutrition food) {
        String aliases = food.getAliases() == null || food.getAliases().isBlank()
                ? "" : "; aliases=" + food.getAliases();
        return "- name=" + food.getName() + aliases
                + "; databaseServing=" + food.getServingSize().stripTrailingZeros().toPlainString()
                + " " + food.getServingUnit()
                + "; kcal=" + food.getCalories().stripTrailingZeros().toPlainString()
                + "; protein=" + food.getProtein().stripTrailingZeros().toPlainString()
                + "g; carbs=" + food.getCarbs().stripTrailingZeros().toPlainString()
                + "g; fat=" + food.getFat().stripTrailingZeros().toPlainString()
                + "g; sugar=" + food.getSugar().stripTrailingZeros().toPlainString() + "g";
    }

    @Transactional
    public void saveFeedback(Integer userId, Integer analysisId, AiFoodFeedbackRequest request) {
        AiFoodAnalysis analysis = analysisRepository
                .findByAiFoodAnalysisIdAndUserUserId(analysisId, userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "AI analysis not found."));
        analysis.setUserConfirmed(request.confirmed());
        analysis.setCorrectedFoodName(request.foodName().trim());
        analysis.setCorrectedServingSize(request.servingSize());
        analysis.setCorrectedServingUnit(request.servingUnit().trim());
        analysis.setFeedbackAt(LocalDateTime.now());
        analysis.setStatus(Boolean.TRUE.equals(request.confirmed()) ? "CONFIRMED" : "CORRECTED");
        analysisRepository.save(analysis);
    }

    private AiFoodAnalysisResponse enrichWithDatabase(
            AiFoodAnalysisResponse ai, List<FoodNutrition> activeFoods) {
        Match match = bestDatabaseMatch(ai.name(), activeFoods);
        boolean databaseMatched = match != null && match.score() >= 0.80;
        if ("IDENTITY_ONLY".equals(ai.dataSource()) && !databaseMatched) {
            throw new ResponseStatusException(
                    org.springframework.http.HttpStatus.BAD_GATEWAY,
                    "The AI identified a possible food, but it could not be verified in the nutrition database.");
        }
        // A text match verifies nutrition data, not whether the image was recognized correctly.
        // Never promote low visual confidence solely because a database name matched.
        double finalConfidence = Math.clamp(ai.confidence(), 0, 1);
        boolean needsConfirmation = finalConfidence < 0.80;
        FoodNutrition food = databaseMatched ? match.food() : null;
        return new AiFoodAnalysisResponse(
                ai.analysisId(),
                food == null ? ai.name() : food.getName(),
                buildDetailedAnalysis(ai, food),
                Math.min(1, finalConfidence),
                food == null ? ai.calories() : food.getCalories().doubleValue(),
                food == null ? ai.protein() : food.getProtein().doubleValue(),
                food == null ? ai.carbs() : food.getCarbs().doubleValue(),
                food == null ? ai.fat() : food.getFat().doubleValue(),
                food == null ? ai.sugar() : food.getSugar().doubleValue(),
                food == null ? ai.servingSize() : food.getServingSize().doubleValue(),
                food == null ? ai.servingUnit() : food.getServingUnit(),
                needsConfirmation ? "Please confirm this food" : ai.recommendationTitle(),
                needsConfirmation
                        ? "Confidence is below 80%. Retake the photo or confirm the food before saving."
                        : ai.recommendation(),
                databaseMatched,
                match == null ? 0 : match.score(),
                needsConfirmation,
                databaseMatched ? "DATABASE_VERIFIED" : "AI_ESTIMATE",
                "AI nutrition values are estimates for wellness information only, not a medical diagnosis or an official nutrition label.",
                "Your food image is sent to the configured AI provider for analysis. Do not include faces, documents, or other personal information.");
    }

    private String buildDetailedAnalysis(AiFoodAnalysisResponse ai, FoodNutrition food) {
        String portion = formatServing(
                food == null ? ai.servingSize() : food.getServingSize().doubleValue(),
                food == null ? ai.servingUnit() : food.getServingUnit());
        double calories = food == null ? ai.calories() : food.getCalories().doubleValue();
        double protein = food == null ? ai.protein() : food.getProtein().doubleValue();
        double carbs = food == null ? ai.carbs() : food.getCarbs().doubleValue();
        double fat = food == null ? ai.fat() : food.getFat().doubleValue();
        double sugar = food == null ? ai.sugar() : food.getSugar().doubleValue();
        String source = food == null
                ? "These values are a validated AI estimate because no strong database name or alias match was found."
                : "The identification and nutrition baseline were verified against the database record for "
                        + food.getName() + ".";
        return "Visual assessment: " + safeAnalysis(ai.analysis())
                + " Portion basis: " + portion + "."
                + " Nutrition interpretation: approximately " + formatNumber(calories) + " kcal, "
                + formatNumber(protein) + " g protein, " + formatNumber(carbs) + " g carbohydrates, "
                + formatNumber(fat) + " g fat, and " + formatNumber(sugar) + " g sugar. " + source;
    }

    private String formatNumber(double value) {
        return BigDecimal.valueOf(value).stripTrailingZeros().toPlainString();
    }

    private Match bestDatabaseMatch(String detectedName, List<FoodNutrition> activeFoods) {
        String detected = normalize(detectedName);
        if (detected.isBlank() || "unknown food".equals(detected)) return null;
        Match best = null;
        for (FoodNutrition food : activeFoods) {
            double score = similarity(detected, normalize(food.getName()));
            if (food.getAliases() != null) {
                for (String alias : food.getAliases().split("[,;|]")) {
                    score = Math.max(score, similarity(detected, normalize(alias)));
                }
            }
            if (best == null || score > best.score()) best = new Match(food, score);
        }
        return best;
    }

    private String normalize(String value) {
        return value == null ? "" : value.toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9\\p{L}]+", " ").trim();
    }

    private String safeAnalysis(String value) {
        return value == null || value.isBlank()
                ? "The AI identified the visible food from its appearance."
                : value.trim();
    }

    private double similarity(String left, String right) {
        if (left.equals(right)) return 1;
        if (left.isBlank() || right.isBlank()) return 0;
        if (left.contains(right) || right.contains(left)) {
            return (double) Math.min(left.length(), right.length()) / Math.max(left.length(), right.length());
        }
        int[] previous = new int[right.length() + 1];
        for (int column = 0; column <= right.length(); column++) previous[column] = column;
        for (int row = 1; row <= left.length(); row++) {
            int[] current = new int[right.length() + 1];
            current[0] = row;
            for (int column = 1; column <= right.length(); column++) {
                int cost = left.charAt(row - 1) == right.charAt(column - 1) ? 0 : 1;
                current[column] = Math.min(Math.min(current[column - 1] + 1, previous[column] + 1),
                        previous[column - 1] + cost);
            }
            previous = current;
        }
        return 1 - (double) previous[right.length()] / Math.max(left.length(), right.length());
    }

    private record Match(FoodNutrition food, double score) {}

    private void saveNutrient(
            AiFoodAnalysis analysis, String name, String unit, int displayOrder, double amount) {
        Nutrient nutrient = nutrientRepository.findByNutrientNameIgnoreCase(name)
                .orElseGet(() -> createNutrient(name, unit, displayOrder));
        AiFoodAnalysisNutrient estimate = new AiFoodAnalysisNutrient();
        estimate.setAiFoodAnalysis(analysis);
        estimate.setNutrient(nutrient);
        estimate.setEstimatedAmount(BigDecimal.valueOf(amount));
        analysisNutrientRepository.save(estimate);
    }

    private Nutrient createNutrient(String name, String unit, int displayOrder) {
        Nutrient nutrient = new Nutrient();
        nutrient.setNutrientName(name);
        nutrient.setUnit(unit);
        nutrient.setDisplayOrder(displayOrder);
        nutrient.setIsCore(true);
        nutrient.setIsActive(true);
        return nutrientRepository.save(nutrient);
    }

    private String formatServing(double size, String unit) {
        String formattedSize = BigDecimal.valueOf(size).stripTrailingZeros().toPlainString();
        return unit == null || unit.isBlank() ? formattedSize : formattedSize + " " + unit.trim();
    }
}
