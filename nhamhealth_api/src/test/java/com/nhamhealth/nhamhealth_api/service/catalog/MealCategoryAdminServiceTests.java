package com.nhamhealth.nhamhealth_api.service.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.nhamhealth.nhamhealth_api.dto.request.AdminMealCategoryRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMealCategoryDto;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.MealCategoryTranslation;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.MealCategoryTranslationRepository;

class MealCategoryAdminServiceTests {

    private MealCategoryRepository mealCategoryRepository;
    private MealRepository mealRepository;
    private MealCategoryTranslationRepository translationRepository;
    private MealCategoryAdminService service;

    @BeforeEach
    void setUp() {
        mealCategoryRepository = mock(MealCategoryRepository.class);
        mealRepository = mock(MealRepository.class);
        translationRepository = mock(MealCategoryTranslationRepository.class);
        service = new MealCategoryAdminService(mealCategoryRepository, mealRepository, translationRepository);
    }

    @Test
    void create_SavesCategoryAndBothTranslations() {
        AdminMealCategoryRequest request = new AdminMealCategoryRequest(
                "Breakfast", "អាហារពេលព្រឹក", "Morning meal", "អាហារពេលព្រឹកដ៏មានជីវជាតិ", true, 1);

        when(mealCategoryRepository.findByCategoryNameIgnoreCase("Breakfast")).thenReturn(Optional.empty());
        when(mealCategoryRepository.save(any(MealCategory.class))).thenAnswer(invocation -> {
            MealCategory cat = invocation.getArgument(0);
            cat.setCategoryId(10);
            return cat;
        });

        MealCategoryTranslation kmTrans = new MealCategoryTranslation();
        kmTrans.setLanguageCode("km");
        kmTrans.setName("អាហារពេលព្រឹក");
        kmTrans.setDescription("អាហារពេលព្រឹកដ៏មានជីវជាតិ");
        when(translationRepository.findByCategoryCategoryIdAndLanguageCode(10, "km"))
                .thenReturn(Optional.of(kmTrans));
        when(mealRepository.countByCategoryCategoryId(10)).thenReturn(0L);

        AdminMealCategoryDto result = service.create(request);

        assertNotNull(result);
        assertEquals(10, result.categoryId());
        assertEquals("Breakfast", result.categoryName());
        assertEquals("អាហារពេលព្រឹក", result.categoryNameKm());
        assertEquals("Morning meal", result.description());
        assertEquals("អាហារពេលព្រឹកដ៏មានជីវជាតិ", result.descriptionKm());

        ArgumentCaptor<MealCategoryTranslation> transCaptor = ArgumentCaptor.forClass(MealCategoryTranslation.class);
        verify(translationRepository, times(2)).save(transCaptor.capture());

        List<MealCategoryTranslation> saved = transCaptor.getAllValues();
        assertEquals("en", saved.get(0).getLanguageCode());
        assertEquals("Breakfast", saved.get(0).getName());
        assertEquals("km", saved.get(1).getLanguageCode());
        assertEquals("អាហារពេលព្រឹក", saved.get(1).getName());
    }

    @Test
    void update_UpdatesKhmerTranslation() {
        MealCategory existing = new MealCategory();
        existing.setCategoryId(5);
        existing.setCategoryName("Lunch");
        existing.setDescription("Midday meal");
        existing.setIsActive(true);
        existing.setSortOrder(2);

        when(mealCategoryRepository.findById(5)).thenReturn(Optional.of(existing));
        when(mealCategoryRepository.findByCategoryNameIgnoreCase("Lunch")).thenReturn(Optional.of(existing));
        when(mealCategoryRepository.save(any(MealCategory.class))).thenAnswer(i -> i.getArgument(0));

        MealCategoryTranslation enTrans = new MealCategoryTranslation();
        enTrans.setCategory(existing);
        enTrans.setLanguageCode("en");
        enTrans.setName("Lunch");
        when(translationRepository.findByCategoryCategoryIdAndLanguageCode(5, "en"))
                .thenReturn(Optional.of(enTrans));

        MealCategoryTranslation kmTrans = new MealCategoryTranslation();
        kmTrans.setCategory(existing);
        kmTrans.setLanguageCode("km");
        kmTrans.setName("អាហារថ្ងៃត្រង់");
        when(translationRepository.findByCategoryCategoryIdAndLanguageCode(5, "km"))
                .thenReturn(Optional.of(kmTrans));

        AdminMealCategoryRequest request = new AdminMealCategoryRequest(
                "Lunch", "អាហារពេលថ្ងៃត្រង់", "Midday meal updated", "ការពិពណ៌នា", true, 2);

        AdminMealCategoryDto result = service.update(5, request);

        assertEquals("Lunch", result.categoryName());
        assertEquals("អាហារពេលថ្ងៃត្រង់", kmTrans.getName());
        assertEquals("ការពិពណ៌នា", kmTrans.getDescription());
        verify(translationRepository, times(2)).save(any(MealCategoryTranslation.class));
    }

    @Test
    void delete_RemovesTranslationsThenCategory() {
        MealCategory category = new MealCategory();
        category.setCategoryId(7);
        when(mealCategoryRepository.findById(7)).thenReturn(Optional.of(category));
        when(mealRepository.countByCategoryCategoryId(7)).thenReturn(0L);

        service.delete(7);

        verify(translationRepository).deleteByCategoryCategoryId(7);
        verify(mealCategoryRepository).delete(category);
    }

    @Test
    void delete_ThrowsWhenCategoryHasMeals() {
        MealCategory category = new MealCategory();
        category.setCategoryId(7);
        when(mealCategoryRepository.findById(7)).thenReturn(Optional.of(category));
        when(mealRepository.countByCategoryCategoryId(7)).thenReturn(3L);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> service.delete(7));
        assertEquals("This category still has meals. Set it inactive instead of deleting it.", ex.getMessage());
    }
}

