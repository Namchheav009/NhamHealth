package com.nhamhealth.nhamhealth_api.controller.api;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import com.nhamhealth.nhamhealth_api.dto.response.FoodNutritionResponse;
import com.nhamhealth.nhamhealth_api.service.catalog.FoodNutritionService;

@RestController
@RequestMapping("/api/v1/foods")
public class FoodNutritionController {
    private final FoodNutritionService service;
    public FoodNutritionController(FoodNutritionService service) { this.service = service; }

    @GetMapping("/search")
    public ResponseEntity<FoodNutritionResponse> search(@RequestParam String name) {
        return service.search(name)
                .map(food -> ResponseEntity.ok(FoodNutritionResponse.from(food)))
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}
