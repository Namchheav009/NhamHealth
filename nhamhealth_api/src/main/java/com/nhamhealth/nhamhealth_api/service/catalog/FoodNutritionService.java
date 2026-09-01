package com.nhamhealth.nhamhealth_api.service.catalog;

import java.util.Arrays;
import java.util.Locale;
import java.util.Optional;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.repository.catalog.FoodNutritionRepository;

@Service
public class FoodNutritionService {
    private final FoodNutritionRepository repository;
    public FoodNutritionService(FoodNutritionRepository repository) { this.repository = repository; }

    @Transactional(readOnly = true)
    public Optional<FoodNutrition> search(String rawName) {
        String name = rawName == null ? "" : rawName.trim();
        if (name.isEmpty()) return Optional.empty();
        Optional<FoodNutrition> result = repository.findFirstByNameAndActiveTrue(name);
        if (result.isPresent()) return result;
        result = repository.findFirstByNameIgnoreCaseAndActiveTrue(name);
        if (result.isPresent()) return result;

        String normalized = name.toLowerCase(Locale.ROOT);
        result = repository.findAliasMatches(name).stream()
                .filter(food -> Arrays.stream(food.getAliases().split("[,\\n]"))
                        .map(String::trim).map(alias -> alias.toLowerCase(Locale.ROOT))
                        .anyMatch(alias -> alias.equals(normalized)))
                .findFirst();
        if (result.isPresent()) return result;
        return repository.findByNameContainingIgnoreCaseAndActiveTrueOrderByNameAsc(name).stream().findFirst();
    }
}
