package com.nhamhealth.nhamhealth_api.service.meal;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;

import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;

import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;

class PlannerIngredientNormalizationServiceTests {
    private final PlannerIngredientNormalizationService service = new PlannerIngredientNormalizationService(
            mock(PlannerMealRepository.class), mock(IngredientRepository.class), mock(JdbcTemplate.class));

    @Test
    void splitsLegacySemicolonIngredientsAndExtractsAmounts() {
        var result = service.parse(
                "180g Greek yogurt; 40g granola; strawberries; 1 piece banana",
                "យ៉ាអួ; ក្រាណូឡា; ស្ត្របឺរី; ចេក");

        assertEquals(4, result.size());
        assertEquals("Greek yogurt", result.get(0).name());
        assertEquals("180", result.get(0).quantity().toPlainString());
        assertEquals("g", result.get(0).unit());
        assertEquals("strawberries", result.get(2).name());
        assertEquals("banana", result.get(3).name());
        assertEquals("piece", result.get(3).unit());
    }

    @Test
    void preservesCanonicalPipeFormat() {
        var result = service.parse("Greek yogurt | 180 | g | យ៉ាអួ\nSalt | 0.5 | tsp | អំបិល", "");
        assertEquals(2, result.size());
        assertEquals("យ៉ាអួ", result.get(0).nameKm());
        assertEquals("0.5", result.get(1).quantity().toPlainString());
    }
}
