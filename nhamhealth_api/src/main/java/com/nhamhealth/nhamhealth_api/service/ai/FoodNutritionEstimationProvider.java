package com.nhamhealth.nhamhealth_api.service.ai;

import java.util.List;

import com.nhamhealth.nhamhealth_api.dto.ai.FoodVisionComponent;

public interface FoodNutritionEstimationProvider {
    FoodNutritionEstimationResult estimate(List<FoodVisionComponent> components);
}
