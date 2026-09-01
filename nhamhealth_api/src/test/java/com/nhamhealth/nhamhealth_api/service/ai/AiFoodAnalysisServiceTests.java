package com.nhamhealth.nhamhealth_api.service.ai;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodCorrectionSuggestionService;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodDatabaseMatchingService;
import com.nhamhealth.nhamhealth_api.service.meal.FoodNutritionCalculationService;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodCandidate;
import com.nhamhealth.nhamhealth_api.dto.ai.AiUserHealthProfile;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodComponentNutritionEstimate;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;
import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionResult;
import com.nhamhealth.nhamhealth_api.dto.request.AiFoodFeedbackRequest;
import com.nhamhealth.nhamhealth_api.dto.response.NutritionSource;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodAnalysisNutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.catalog.NutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodDatabaseMatchingService.MatchCandidate;

class AiFoodAnalysisServiceTests {
    @Test
    void calculatesMealNutritionFromMatchedComponents() {
        FoodVisionProvider visionProvider = mock(FoodVisionProvider.class);
        FoodDatabaseMatchingService matchingService = mock(FoodDatabaseMatchingService.class);
        FoodNutritionEstimationProvider estimationProvider =
                mock(FoodNutritionEstimationProvider.class);
        UserRepository userRepository = mock(UserRepository.class);
        AiFoodAnalysisRepository analysisRepository = mock(AiFoodAnalysisRepository.class);
        AiFoodAnalysisNutrientRepository analysisNutrientRepository =
                mock(AiFoodAnalysisNutrientRepository.class);
        NutrientRepository nutrientRepository = mock(NutrientRepository.class);
        AiUserHealthProfileService userHealthProfileService = mock(AiUserHealthProfileService.class);
        User user = new User();
        when(userRepository.findById(7)).thenReturn(Optional.of(user));
        when(userHealthProfileService.load(7)).thenReturn(completeHealthProfile());
        when(nutrientRepository.findByNutrientNameIgnoreCase(any()))
                .thenReturn(Optional.of(new Nutrient()));

        FoodVisionComponent riceDetection = new FoodVisionComponent(
                "Cooked rice", 200, "g", 0.90, 0.82,
                "steamed", "white rice occupies half the plate");
        FoodVisionResult vision = new FoodVisionResult(
                true, "", "Chicken Rice", "Unknown", "food",
                0.82, 0.80, 0.82,
                List.of(riceDetection),
                List.of(
                        new FoodCandidate("Chicken Rice", 0.82),
                        new FoodCandidate("Fried Rice", 0.10)));
        when(visionProvider.analyze(any(), any())).thenReturn(new AiFoodModelResult(
                vision, "vision-model", "prompt-v1", false, 10, 20, 100));
        FoodNutrition rice = food();
        when(matchingService.findReliableMatches(List.of("Cooked rice")))
                .thenReturn(List.of(Optional.of(new MatchCandidate(rice, 0.95))));

        AiFoodAnalysisService service = new AiFoodAnalysisService(
                visionProvider,
                matchingService,
                new FoodNutritionCalculationService(),
                estimationProvider,
                new FoodAnalysisConfidencePolicy(0.75, 0.15, 0.70, 0.65),
                mock(FoodCorrectionSuggestionService.class),
                userHealthProfileService,
                userRepository,
                analysisRepository,
                analysisNutrientRepository,
                nutrientRepository);

        var result = service.analyzeAndSave(
                7, "food.jpg", new byte[] {1, 2, 3}, "image/jpeg");

        assertEquals("Chicken Rice", result.mealName());
        assertEquals(260, result.nutrition().calories());
        assertEquals(56, result.nutrition().carbohydrates());
        assertEquals(NutritionSource.DATABASE_CALCULATED, result.nutrition().source());
        assertTrue(result.databaseMatched());
        assertFalse(result.needsUserConfirmation());
        assertEquals("Personalized nutrition check", result.recommendationTitle());
        assertTrue(result.recommendation().contains("height 172 cm and weight 68 kg"));
        verify(visionProvider).analyze(any(), any());
        verify(userHealthProfileService).load(7);
    }

    @Test
    void estimatesNutritionForARecognizedComponentMissingFromTheDatabase() {
        FoodVisionProvider visionProvider = mock(FoodVisionProvider.class);
        FoodDatabaseMatchingService matchingService = mock(FoodDatabaseMatchingService.class);
        FoodNutritionEstimationProvider estimationProvider =
                mock(FoodNutritionEstimationProvider.class);
        UserRepository userRepository = mock(UserRepository.class);
        AiFoodAnalysisRepository analysisRepository = mock(AiFoodAnalysisRepository.class);
        AiFoodAnalysisNutrientRepository analysisNutrientRepository =
                mock(AiFoodAnalysisNutrientRepository.class);
        NutrientRepository nutrientRepository = mock(NutrientRepository.class);
        AiUserHealthProfileService userHealthProfileService = mock(AiUserHealthProfileService.class);
        User user = new User();
        when(userRepository.findById(7)).thenReturn(Optional.of(user));
        when(userHealthProfileService.load(7)).thenReturn(AiUserHealthProfile.empty(7));
        when(nutrientRepository.findByNutrientNameIgnoreCase(any()))
                .thenReturn(Optional.of(new Nutrient()));

        FoodVisionComponent drink = new FoodVisionComponent(
                "Chocolate Frappuccino", 350, "ml", 0.95, 0.82,
                "blended", "a chocolate blended coffee drink fills the cup");
        FoodVisionResult vision = new FoodVisionResult(
                true, "", "Chocolate Frappuccino", "Unknown", "drink",
                0.95, 0.82, 0.80,
                List.of(drink),
                List.of(new FoodCandidate("Chocolate Frappuccino", 0.95)));
        when(visionProvider.analyze(any(), any())).thenReturn(new AiFoodModelResult(
                vision, "vision-model", "prompt-v1", false, 10, 20, 100));
        when(matchingService.findReliableMatches(List.of("Chocolate Frappuccino")))
                .thenReturn(List.of(Optional.empty()));
        when(estimationProvider.estimate(List.of(drink))).thenReturn(
                new FoodNutritionEstimationResult(
                        List.of(new FoodComponentNutritionEstimate(
                                0, 420, 6, 68, 14, 55, 2, 260, 0.68)),
                        "nutrition-model", 15, 25, 80));

        AiFoodAnalysisService service = new AiFoodAnalysisService(
                visionProvider,
                matchingService,
                new FoodNutritionCalculationService(),
                estimationProvider,
                new FoodAnalysisConfidencePolicy(0.75, 0.15, 0.70, 0.65),
                mock(FoodCorrectionSuggestionService.class),
                userHealthProfileService,
                userRepository,
                analysisRepository,
                analysisNutrientRepository,
                nutrientRepository);

        var result = service.analyzeAndSave(
                7, "drink.jpg", new byte[] {1, 2, 3}, "image/jpeg");

        assertEquals(420, result.nutrition().calories());
        assertEquals(68, result.nutrition().carbohydrates());
        assertEquals(NutritionSource.AI_ESTIMATED, result.nutrition().source());
        assertTrue(result.nutrition().complete());
        assertTrue(result.needsUserConfirmation());
        assertFalse(result.databaseMatched());
        verify(estimationProvider).estimate(List.of(drink));
    }

    @Test
    void routesAnEditedResultToTheCorrectionSuggestionStore() {
        AiFoodAnalysisRepository analysisRepository = mock(AiFoodAnalysisRepository.class);
        FoodCorrectionSuggestionService correctionService =
                mock(FoodCorrectionSuggestionService.class);
        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setDetectedFoodName("Unknown tea");
        analysis.setDetectedServingText("1 serving");
        when(analysisRepository.findByAiFoodAnalysisIdAndUserUserId(42, 7))
                .thenReturn(Optional.of(analysis));
        AiFoodFeedbackRequest correction = new AiFoodFeedbackRequest(
                false, "Thai Iced Tea", BigDecimal.valueOf(350), "ml");
        when(correctionService.recordCorrection(analysis, correction)).thenReturn(true);
        AiFoodAnalysisService service = new AiFoodAnalysisService(
                mock(FoodVisionProvider.class),
                mock(FoodDatabaseMatchingService.class),
                new FoodNutritionCalculationService(),
                mock(FoodNutritionEstimationProvider.class),
                new FoodAnalysisConfidencePolicy(0.75, 0.15, 0.70, 0.65),
                correctionService,
                mock(AiUserHealthProfileService.class),
                mock(UserRepository.class),
                analysisRepository,
                mock(AiFoodAnalysisNutrientRepository.class),
                mock(NutrientRepository.class));

        service.saveFeedback(7, 42, correction);

        assertEquals("CORRECTED", analysis.getStatus());
        assertEquals("Thai Iced Tea", analysis.getCorrectedFoodName());
        assertFalse(Boolean.TRUE.equals(analysis.getUserConfirmed()));
        verify(correctionService).recordCorrection(analysis, correction);
        verify(analysisRepository).save(analysis);
    }

    private FoodNutrition food() {
        FoodNutrition food = new FoodNutrition();
        food.setName("Cooked Jasmine Rice");
        food.setCalories(BigDecimal.valueOf(130));
        food.setProtein(BigDecimal.valueOf(2.7));
        food.setCarbs(BigDecimal.valueOf(28));
        food.setFat(BigDecimal.valueOf(0.3));
        food.setSugar(BigDecimal.valueOf(0.1));
        food.setFiber(BigDecimal.valueOf(0.4));
        food.setSodium(BigDecimal.ONE);
        food.setServingSize(BigDecimal.valueOf(100));
        food.setServingUnit("g");
        food.setActive(true);
        return food;
    }

    private AiUserHealthProfile completeHealthProfile() {
        return new AiUserHealthProfile(
                7,
                (short) 29,
                BigDecimal.valueOf(172),
                BigDecimal.valueOf(68),
                BigDecimal.valueOf(23.0),
                "moderate");
    }
}
