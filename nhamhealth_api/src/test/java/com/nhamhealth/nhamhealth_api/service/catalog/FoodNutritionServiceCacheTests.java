package com.nhamhealth.nhamhealth_api.service.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ContextConfiguration;
import org.springframework.test.context.junit.jupiter.SpringExtension;

import com.nhamhealth.nhamhealth_api.config.CacheConfig;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.repository.catalog.FoodNutritionRepository;

@ExtendWith(SpringExtension.class)
@ContextConfiguration(classes = { FoodNutritionServiceCacheTests.TestConfig.class })
class FoodNutritionServiceCacheTests {

    @Configuration
    @Import(CacheConfig.class)
    static class TestConfig {
        @Bean
        FoodNutritionRepository foodNutritionRepository() {
            return mock(FoodNutritionRepository.class);
        }

        @Bean
        FoodNutritionService foodNutritionService(FoodNutritionRepository repository) {
            return new FoodNutritionService(repository);
        }
    }

    @Autowired
    private FoodNutritionService foodNutritionService;

    @Autowired
    private FoodNutritionRepository repository;

    @Test
    void searchReturnsEmptyWithoutSpelEvaluationException() {
        when(repository.findFirstByNameAndActiveTrue("unknown food")).thenReturn(Optional.empty());
        when(repository.findFirstByNameIgnoreCaseAndActiveTrue("unknown food")).thenReturn(Optional.empty());

        Optional<FoodNutrition> result = foodNutritionService.search("unknown food");

        assertFalse(result.isPresent());
    }

    @Test
    void searchCachesSuccessfulResult() {
        FoodNutrition apple = new FoodNutrition();
        apple.setName("Apple");
        apple.setServingSize(new BigDecimal("100.00"));

        when(repository.findFirstByNameAndActiveTrue("apple")).thenReturn(Optional.of(apple));

        Optional<FoodNutrition> first = foodNutritionService.search("apple");
        assertTrue(first.isPresent());
        assertEquals("Apple", first.get().getName());

        Optional<FoodNutrition> second = foodNutritionService.search("apple");
        assertTrue(second.isPresent());
        assertEquals("Apple", second.get().getName());

        verify(repository, times(1)).findFirstByNameAndActiveTrue("apple");
    }
}