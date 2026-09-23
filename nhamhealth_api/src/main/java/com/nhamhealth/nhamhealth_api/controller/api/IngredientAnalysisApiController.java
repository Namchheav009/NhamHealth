package com.nhamhealth.nhamhealth_api.controller.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.request.IngredientAnalysisRequest;
import com.nhamhealth.nhamhealth_api.dto.response.IngredientAnalysisResponse;
import com.nhamhealth.nhamhealth_api.service.ai.AiIngredientAnalysisService;

import jakarta.validation.Valid;

@RestController
@RequestMapping({"/api/v1/meal-planner/ingredients", "/api/v1/ingredients"})
public class IngredientAnalysisApiController {

    private final AiIngredientAnalysisService analysisService;

    public IngredientAnalysisApiController(AiIngredientAnalysisService analysisService) {
        this.analysisService = analysisService;
    }

    @PostMapping("/analyze")
    public ResponseEntity<IngredientAnalysisResponse> analyzeIngredients(
            @Valid @RequestBody IngredientAnalysisRequest request) {
        return ResponseEntity.ok(analysisService.analyze(request));
    }
}
