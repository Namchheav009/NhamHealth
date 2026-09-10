package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.nhamhealth.nhamhealth_api.dto.response.MealCategoryResponse;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.MealCategoryTranslation;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.MealCategoryTranslationRepository;

class MealCategoryApiControllerTests {

    private MealCategoryRepository mealCategoryRepository;
    private MealCategoryTranslationRepository translationRepository;
    private MealCategoryApiController controller;

    @BeforeEach
    void setUp() {
        mealCategoryRepository = mock(MealCategoryRepository.class);
        translationRepository = mock(MealCategoryTranslationRepository.class);
        controller = new MealCategoryApiController(mealCategoryRepository, translationRepository);
    }

    @Test
    void activeMealCategories_ReturnsEnglishByDefault() {
        MealCategory cat1 = new MealCategory();
        cat1.setCategoryId(1);
        cat1.setCategoryName("Breakfast");

        MealCategoryTranslation km1 = new MealCategoryTranslation();
        km1.setCategory(cat1);
        km1.setLanguageCode("km");
        km1.setName("អាហារពេលព្រឹក");

        when(mealCategoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc()).thenReturn(List.of(cat1));
        when(translationRepository.findByLanguageCode("km")).thenReturn(List.of(km1));

        ResponseEntity<List<MealCategoryResponse>> response = controller.activeMealCategories("en");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().size());

        MealCategoryResponse item = response.getBody().get(0);
        assertEquals(1, item.id());
        assertEquals("Breakfast", item.name());
        assertEquals("អាហារពេលព្រឹក", item.nameKm());
    }

    @Test
    void activeMealCategories_ReturnsKhmerWhenRequested() {
        MealCategory cat1 = new MealCategory();
        cat1.setCategoryId(1);
        cat1.setCategoryName("Breakfast");

        MealCategoryTranslation km1 = new MealCategoryTranslation();
        km1.setCategory(cat1);
        km1.setLanguageCode("km");
        km1.setName("អាហារពេលព្រឹក");

        when(mealCategoryRepository.findAllByIsActiveTrueOrderBySortOrderAsc()).thenReturn(List.of(cat1));
        when(translationRepository.findByLanguageCode("km")).thenReturn(List.of(km1));

        ResponseEntity<List<MealCategoryResponse>> response = controller.activeMealCategories("km");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().size());

        MealCategoryResponse item = response.getBody().get(0);
        assertEquals(1, item.id());
        assertEquals("អាហារពេលព្រឹក", item.name());
        assertEquals("អាហារពេលព្រឹក", item.nameKm());
    }
}

