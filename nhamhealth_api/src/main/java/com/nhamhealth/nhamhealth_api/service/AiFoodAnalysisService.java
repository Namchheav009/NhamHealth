package com.nhamhealth.nhamhealth_api.service;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;
import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysisNutrient;
import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisNutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.NutrientRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Service
public class AiFoodAnalysisService {
    private final NvidiaFoodVisionService visionService;
    private final UserRepository userRepository;
    private final AiFoodAnalysisRepository analysisRepository;
    private final AiFoodAnalysisNutrientRepository analysisNutrientRepository;
    private final NutrientRepository nutrientRepository;

    public AiFoodAnalysisService(
            NvidiaFoodVisionService visionService,
            UserRepository userRepository,
            AiFoodAnalysisRepository analysisRepository,
            AiFoodAnalysisNutrientRepository analysisNutrientRepository,
            NutrientRepository nutrientRepository) {
        this.visionService = visionService;
        this.userRepository = userRepository;
        this.analysisRepository = analysisRepository;
        this.analysisNutrientRepository = analysisNutrientRepository;
        this.nutrientRepository = nutrientRepository;
    }

    @Transactional
    public AiFoodAnalysisResponse analyzeAndSave(
            Integer userId, String fileName, byte[] image, String contentType) {
        AiFoodAnalysisResponse result = visionService.analyze(image, contentType);
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));

        AiFoodAnalysis analysis = new AiFoodAnalysis();
        analysis.setUser(user);
        analysis.setInputText(fileName == null || fileName.isBlank() ? "Food image" : fileName);
        analysis.setDetectedFoodName(result.name());
        analysis.setDetectedServingText(formatServing(result.servingSize(), result.servingUnit()));
        analysis.setConfidenceScore(BigDecimal.valueOf(result.confidence()));
        analysis.setStatus("COMPLETED");
        analysis.setCreatedAt(LocalDateTime.now());
        analysisRepository.saveAndFlush(analysis);

        saveNutrient(analysis, "Calories", "kcal", 1, result.calories());
        saveNutrient(analysis, "Protein", "g", 2, result.protein());
        saveNutrient(analysis, "Carbs", "g", 3, result.carbs());
        saveNutrient(analysis, "Fat", "g", 4, result.fat());
        saveNutrient(analysis, "Sugar", "g", 5, result.sugar());
        return result;
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
}
