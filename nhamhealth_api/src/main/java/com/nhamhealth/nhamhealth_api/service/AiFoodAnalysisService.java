package com.nhamhealth.nhamhealth_api.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Locale;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;
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

@Service
public class AiFoodAnalysisService {
    private final NvidiaFoodVisionService visionService;
    private final UserRepository userRepository;
    private final AiFoodAnalysisRepository analysisRepository;
    private final AiFoodAnalysisNutrientRepository analysisNutrientRepository;
    private final NutrientRepository nutrientRepository;
    private final FoodNutritionRepository foodNutritionRepository;

    public AiFoodAnalysisService(
            NvidiaFoodVisionService visionService,
            UserRepository userRepository,
            AiFoodAnalysisRepository analysisRepository,
            AiFoodAnalysisNutrientRepository analysisNutrientRepository,
            NutrientRepository nutrientRepository,
            FoodNutritionRepository foodNutritionRepository) {
        this.visionService = visionService;
        this.userRepository = userRepository;
        this.analysisRepository = analysisRepository;
        this.analysisNutrientRepository = analysisNutrientRepository;
        this.nutrientRepository = nutrientRepository;
        this.foodNutritionRepository = foodNutritionRepository;
    }

    @Transactional
    public AiFoodAnalysisResponse analyzeAndSave(
            Integer userId, String fileName, byte[] image, String contentType) {
        AiFoodAnalysisResponse result = enrichWithDatabase(visionService.analyze(image, contentType));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setUser(user);
        analysis.setInputText(fileName == null || fileName.isBlank() ? "Food image" : fileName);
        analysis.setDetectedFoodName(result.name());
        analysis.setAnalysisText(result.analysis());
        analysis.setDetectedServingText(formatServing(result.servingSize(), result.servingUnit()));
        analysis.setConfidenceScore(BigDecimal.valueOf(result.confidence()));
        analysis.setStatus(result.needsUserConfirmation() ? "REVIEW" : "COMPLETED");
        analysis.setCreatedAt(LocalDateTime.now());
        analysisRepository.saveAndFlush(analysis);

        saveNutrient(analysis, "Calories", "kcal", 1, result.calories());
        saveNutrient(analysis, "Protein", "g", 2, result.protein());
        saveNutrient(analysis, "Carbs", "g", 3, result.carbs());
        saveNutrient(analysis, "Fat", "g", 4, result.fat());
        saveNutrient(analysis, "Sugar", "g", 5, result.sugar());
        return result;
    }

    private AiFoodAnalysisResponse enrichWithDatabase(AiFoodAnalysisResponse ai) {
        Match match = bestDatabaseMatch(ai.name());
        boolean databaseMatched = match != null && match.score() >= 0.80;
        // A text match verifies nutrition data, not whether the image was recognized correctly.
        // Never promote low visual confidence solely because a database name matched.
        double finalConfidence = Math.clamp(ai.confidence(), 0, 1);
        boolean needsConfirmation = finalConfidence < 0.80;
        FoodNutrition food = databaseMatched ? match.food() : null;
        return new AiFoodAnalysisResponse(
                food == null ? ai.name() : food.getName(),
                databaseMatched
                        ? safeAnalysis(ai.analysis()) + " Nutrition values matched the database record for " + food.getName() + "."
                        : safeAnalysis(ai.analysis()),
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

    private Match bestDatabaseMatch(String detectedName) {
        String detected = normalize(detectedName);
        if (detected.isBlank() || "unknown food".equals(detected)) return null;
        Match best = null;
        for (FoodNutrition food : foodNutritionRepository.findAllByActiveTrue()) {
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
