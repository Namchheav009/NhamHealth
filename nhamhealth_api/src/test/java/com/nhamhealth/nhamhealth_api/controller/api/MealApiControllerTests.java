package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import com.nhamhealth.nhamhealth_api.dto.response.MealDetailResponse;
import com.nhamhealth.nhamhealth_api.repository.meal.MealRepository;
import com.nhamhealth.nhamhealth_api.service.meal.MealTranslationService;

class MealApiControllerTests {
    @Test
    void returnsRequestedLocalizedMealDetail() {
        MealRepository meals=mock(MealRepository.class);
        MealTranslationService translations=mock(MealTranslationService.class);
        MealDetailResponse detail=new MealDetailResponse(42,"km","បាយសាច់ជ្រូក",5,"អាហារពេលព្រឹក","/meal.jpg",new BigDecimal("470"),"",35,"EASY",1,List.of(),List.of(),List.of(),List.of(),List.of());
        when(translations.detail(42,"km")).thenReturn(Optional.of(detail));
        var response=new MealApiController(meals,translations).publishedMeal(42,"km");
        assertEquals(HttpStatus.OK,response.getStatusCode());
        assertEquals("បាយសាច់ជ្រូក",response.getBody().name());
        assertEquals("km",response.getBody().languageCode());
    }
}
