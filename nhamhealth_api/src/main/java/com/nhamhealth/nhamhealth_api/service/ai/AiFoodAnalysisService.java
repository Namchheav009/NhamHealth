package com.nhamhealth.nhamhealth_api.service.ai;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodCorrectionSuggestionService;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodDatabaseMatchingService;
import com.nhamhealth.nhamhealth_api.service.meal.FoodNutritionCalculationService;

import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionResult;
import com.nhamhealth.nhamhealth_api.dto.ai.AiUserHealthProfile;
import com.nhamhealth.nhamhealth_api.dto.request.AiFoodFeedbackRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;
import com.nhamhealth.nhamhealth_api.dto.response.DetectedFoodComponent;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSource;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSummaryResponse;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysisNutrient;
import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodAnalysisNutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.catalog.NutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodDatabaseMatchingService.MatchCandidate;

@Service
public class AiFoodAnalysisService {
    private static final Logger log = LoggerFactory.getLogger(AiFoodAnalysisService.class);
    private static final String DISCLAIMER =
            "Nutrition is calculated from matched database foods when available; unmatched components may use a clearly labeled AI estimate. Results are for general wellness only, not medical advice or an official nutrition label.";
    private static final String PRIVACY_NOTICE =
            "Your food image is sent to the configured AI provider for recognition. Do not include faces, documents, or other personal information.";

    private final FoodVisionProvider visionProvider;
    private final FoodDatabaseMatchingService matchingService;
    private final FoodNutritionCalculationService calculationService;
    private final FoodNutritionEstimationProvider nutritionEstimationProvider;
    private final FoodAnalysisConfidencePolicy confidencePolicy;
    private final FoodCorrectionSuggestionService correctionSuggestionService;
    private final AiUserHealthProfileService userHealthProfileService;
    private final UserRepository userRepository;
    private final AiFoodAnalysisRepository analysisRepository;
    private final AiFoodAnalysisNutrientRepository analysisNutrientRepository;
    private final NutrientRepository nutrientRepository;

    public AiFoodAnalysisService(
            FoodVisionProvider visionProvider,
            FoodDatabaseMatchingService matchingService,
            FoodNutritionCalculationService calculationService,
            FoodNutritionEstimationProvider nutritionEstimationProvider,
            FoodAnalysisConfidencePolicy confidencePolicy,
            FoodCorrectionSuggestionService correctionSuggestionService,
            AiUserHealthProfileService userHealthProfileService,
            UserRepository userRepository,
            AiFoodAnalysisRepository analysisRepository,
            AiFoodAnalysisNutrientRepository analysisNutrientRepository,
            NutrientRepository nutrientRepository) {
        this.visionProvider = visionProvider;
        this.matchingService = matchingService;
        this.calculationService = calculationService;
        this.nutritionEstimationProvider = nutritionEstimationProvider;
        this.confidencePolicy = confidencePolicy;
        this.correctionSuggestionService = correctionSuggestionService;
        this.userHealthProfileService = userHealthProfileService;
        this.userRepository = userRepository;
        this.analysisRepository = analysisRepository;
        this.analysisNutrientRepository = analysisNutrientRepository;
        this.nutrientRepository = nutrientRepository;
    }

    @Transactional
    public AiFoodAnalysisResponse analyzeAndSave(
            Integer userId, String fileName, byte[] image, String contentType) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        AiUserHealthProfile healthProfile = userHealthProfileService.load(userId);
        AiFoodModelResult modelResult = visionProvider.analyze(image, contentType);
        FoodVisionResult vision = modelResult.response();

        ComponentEnrichment enrichment = matchCalculateAndEstimate(vision.components());
        List<DetectedFoodComponent> components = enrichment.components();
        FoodNutritionEstimationResult estimation = enrichment.estimation();
        NutritionSummaryResponse nutrition = calculationService.aggregate(components);
        boolean needsConfirmation = confidencePolicy.requiresConfirmation(vision, components);
        AiFoodAnalysisResponse result = buildResponse(
                vision, components, nutrition, needsConfirmation, healthProfile);

        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setUser(user);
        analysis.setInputText(fileName == null || fileName.isBlank() ? "Food image" : fileName);
        analysis.setDetectedFoodName(result.name());
        analysis.setAnalysisText(limit(result.analysis(), 1_000));
        analysis.setDetectedServingText(formatServing(result.servingSize(), result.servingUnit()));
        analysis.setConfidenceScore(BigDecimal.valueOf(result.mealIdentityConfidence()));
        analysis.setStatus(!result.foodDetected()
                ? "FAILED" : result.needsUserConfirmation() ? "NEEDS_CONFIRMATION" : "COMPLETED");
        analysis.setCreatedAt(LocalDateTime.now());
        String modelsUsed = estimation.used() && !estimation.modelName().isBlank()
                ? modelResult.modelName() + " + " + estimation.modelName()
                : modelResult.modelName();
        analysis.setModelName(limit(modelsUsed, 120));
        analysis.setPromptVersion(modelResult.promptVersion());
        analysis.setDatabaseMatched(result.databaseMatched());
        analysis.setNutritionFallbackUsed(estimation.used());
        analysis.setPromptTokens(modelResult.promptTokens() + estimation.promptTokens());
        analysis.setCompletionTokens(
                modelResult.completionTokens() + estimation.completionTokens());
        analysis.setLatencyMs(modelResult.latencyMs() + estimation.latencyMs());
        analysisRepository.saveAndFlush(analysis);

        saveNutrient(analysis, "Calories", "kcal", 1, nutrition.calories());
        saveNutrient(analysis, "Protein", "g", 2, nutrition.protein());
        saveNutrient(analysis, "Carbs", "g", 3, nutrition.carbohydrates());
        saveNutrient(analysis, "Fat", "g", 4, nutrition.fat());
        saveNutrient(analysis, "Sugar", "g", 5, nutrition.sugar());
        saveNutrient(analysis, "Fiber", "g", 6, nutrition.fiber());
        saveNutrient(analysis, "Sodium", "mg", 7, nutrition.sodium());

        int databaseMatchCount = (int) components.stream()
                .filter(DetectedFoodComponent::databaseMatched).count();
        log.info("AI food analysis completed analysisId={} providerModel={} durationMs={} foodDetected={} componentCount={} databaseMatchCount={} aiEstimatedCount={} needsConfirmation={} nutritionSource={}",
                analysis.getAiFoodAnalysisId(), modelsUsed, analysis.getLatencyMs(),
                result.foodDetected(), components.size(), databaseMatchCount,
                estimation.components().size(),
                needsConfirmation, nutrition.source());
        return result.withAnalysisId(analysis.getAiFoodAnalysisId());
    }

    private ComponentEnrichment matchCalculateAndEstimate(List<FoodVisionComponent> detected) {
        if (detected == null || detected.isEmpty()) {
            return new ComponentEnrichment(List.of(), FoodNutritionEstimationResult.empty());
        }
        List<Optional<MatchCandidate>> matches = matchingService.findReliableMatches(
                detected.stream().map(FoodVisionComponent::name).toList());
        List<DetectedFoodComponent> calculated = new ArrayList<>(detected.size());
        for (int index = 0; index < detected.size(); index++) {
            Optional<MatchCandidate> match = index < matches.size()
                    ? matches.get(index) : Optional.empty();
            calculated.add(calculationService.calculate(detected.get(index), match));
        }

        List<Integer> pendingIndexes = new ArrayList<>();
        List<FoodVisionComponent> pendingComponents = new ArrayList<>();
        for (int index = 0; index < calculated.size(); index++) {
            if (calculated.get(index).nutritionSource() == NutritionSource.UNAVAILABLE) {
                pendingIndexes.add(index);
                pendingComponents.add(detected.get(index));
            }
        }
        if (pendingComponents.isEmpty()) {
            return new ComponentEnrichment(
                    List.copyOf(calculated), FoodNutritionEstimationResult.empty());
        }

        try {
            FoodNutritionEstimationResult estimation =
                    nutritionEstimationProvider.estimate(List.copyOf(pendingComponents));
            for (var estimate : estimation.components()) {
                int originalIndex = pendingIndexes.get(estimate.index());
                calculated.set(originalIndex, calculationService.applyAiEstimate(
                        calculated.get(originalIndex), estimate));
            }
            return new ComponentEnrichment(List.copyOf(calculated), estimation);
        } catch (RuntimeException error) {
            log.warn("AI nutrition fallback was unavailable; returning an incomplete result: {}",
                    safeMessage(error));
            return new ComponentEnrichment(
                    List.copyOf(calculated), FoodNutritionEstimationResult.empty());
        }
    }

    private AiFoodAnalysisResponse buildResponse(
            FoodVisionResult vision,
            List<DetectedFoodComponent> components,
            NutritionSummaryResponse nutrition,
            boolean needsConfirmation,
            AiUserHealthProfile healthProfile) {
        boolean databaseMatched = nutrition.complete()
                && !components.isEmpty()
                && components.stream().allMatch(DetectedFoodComponent::databaseMatched);
        double databaseMatchConfidence = components.stream()
                .filter(DetectedFoodComponent::databaseMatched)
                .mapToDouble(DetectedFoodComponent::databaseMatchConfidence)
                .average().orElse(0);
        String mealName = vision.foodDetected() ? vision.mealName() : "Unknown food";
        String recommendationTitle;
        String recommendation;
        if (!vision.foodDetected()) {
            recommendationTitle = "Try another photo";
            recommendation = "Use better lighting and show the entire food or drink clearly.";
        } else if (!nutrition.complete()) {
            recommendationTitle = "Review meal components";
            recommendation = "One or more components could not be calculated safely from the nutrition database.";
        } else if (needsConfirmation) {
            recommendationTitle = "Please confirm this meal";
            recommendation = "Review the meal identity and component portions before saving.";
        } else if (healthProfile.hasHeightAndWeight()) {
            recommendationTitle = "Personalized nutrition check";
            recommendation = "Using your saved BMI "
                    + decimal(healthProfile.bmi())
                    + " as general wellness context, compare this meal's "
                    + wholeNumber(nutrition.calories()) + " kcal and "
                    + wholeNumber(nutrition.protein())
                    + " g protein with your daily wellness goals.";
        } else {
            recommendationTitle = "Database nutrition calculated";
            recommendation = "Nutrition was calculated from the matched components and visible portions.";
        }
        return new AiFoodAnalysisResponse(
                null,
                mealName,
                buildAnalysis(vision, components, nutrition),
                vision.mealConfidence(),
                nutrition.calories(),
                nutrition.protein(),
                nutrition.carbohydrates(),
                nutrition.fat(),
                nutrition.sugar(),
                1,
                "serving",
                recommendationTitle,
                recommendation,
                databaseMatched,
                round(databaseMatchConfidence, 3),
                needsConfirmation,
                nutrition.source().name(),
                DISCLAIMER,
                PRIVACY_NOTICE,
                vision.foodDetected(),
                vision.reason(),
                mealName,
                vision.cuisine(),
                vision.type(),
                "drink".equals(vision.type()) || "mixed".equals(vision.type()),
                vision.mealConfidence(),
                vision.portionConfidence(),
                vision.preparationConfidence(),
                components,
                vision.candidates(),
                nutrition);
    }

    private String decimal(BigDecimal value) {
        return value.stripTrailingZeros().toPlainString();
    }

    private String buildAnalysis(
            FoodVisionResult vision,
            List<DetectedFoodComponent> components,
            NutritionSummaryResponse nutrition) {
        if (!vision.foodDetected()) return vision.reason();
        String componentSummary = components.stream()
                .map(component -> component.name() + " "
                        + formatServing(component.estimatedAmount(), component.unit())
                        + (component.databaseMatched()
                                ? " matched to " + component.matchedFoodName()
                                : " not matched"))
                .reduce((left, right) -> left + "; " + right)
                .orElse("No components were returned");
        String completeness = nutrition.complete()
                ? switch (nutrition.source()) {
                    case DATABASE_CALCULATED ->
                            "All component nutrition was calculated from database records.";
                    case AI_ESTIMATED ->
                            "Component nutrition is an AI estimate and requires confirmation.";
                    case HYBRID_ESTIMATED ->
                            "Nutrition combines database calculations with AI estimates and requires confirmation.";
                    default -> "The component nutrition estimate is complete.";
                }
                : "The nutrition total is incomplete and requires review.";
        return "Recognized " + vision.mealName() + ". Components: "
                + componentSummary + ". " + completeness;
    }

    @Transactional
    public void saveFeedback(Integer userId, Integer analysisId, AiFoodFeedbackRequest request) {
        AiFoodAnalysis analysis = analysisRepository
                .findByAiFoodAnalysisIdAndUserUserId(analysisId, userId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "AI analysis not found."));
        analysis.setCorrectedFoodName(request.foodName().trim());
        analysis.setCorrectedServingSize(request.servingSize());
        analysis.setCorrectedServingUnit(request.servingUnit().trim());
        analysis.setFeedbackAt(LocalDateTime.now());
        boolean correctionRecorded = correctionSuggestionService.recordCorrection(
                analysis, request);
        analysis.setUserConfirmed(!correctionRecorded && Boolean.TRUE.equals(request.confirmed()));
        analysis.setStatus(correctionRecorded ? "CORRECTED" : "CONFIRMED");
        analysisRepository.saveAndFlush(analysis);
    }

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

    private String wholeNumber(double value) {
        return BigDecimal.valueOf(value).setScale(0, java.math.RoundingMode.HALF_UP).toPlainString();
    }

    private String limit(String value, int maximum) {
        if (value == null) return "";
        return value.length() <= maximum ? value : value.substring(0, maximum);
    }

    private double round(double value, int scale) {
        double factor = Math.pow(10, scale);
        return Math.round(value * factor) / factor;
    }

    private String safeMessage(Throwable error) {
        Throwable root = error;
        while (root.getCause() != null && root.getCause() != root) root = root.getCause();
        String message = root.getMessage();
        if (message == null || message.isBlank()) return root.getClass().getSimpleName();
        message = message.replaceAll("[\\r\\n\\t]+", " ");
        return message.length() <= 240 ? message : message.substring(0, 240);
    }

    private record ComponentEnrichment(
            List<DetectedFoodComponent> components,
            FoodNutritionEstimationResult estimation) {
    }
}
