package com.nhamhealth.nhamhealth_api.service.catalog;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.nhamhealth.nhamhealth_api.dto.request.AdminIngredientRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AdminIngredientDto;
import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.entity.IngredientTranslation;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.IngredientTranslationRepository;

import jakarta.persistence.EntityManager;
import jakarta.persistence.Query;

class IngredientAdminServiceTests {

    private IngredientRepository ingredientRepository;
    private IngredientTranslationRepository ingredientTranslationRepository;
    private EntityManager entityManager;
    private IngredientAdminService service;

    @BeforeEach
    void setUp() {
        ingredientRepository = mock(IngredientRepository.class);
        ingredientTranslationRepository = mock(IngredientTranslationRepository.class);
        entityManager = mock(EntityManager.class);
        service = new IngredientAdminService(ingredientRepository, ingredientTranslationRepository, entityManager);
    }

    @Test
    void create_SavesIngredientAndBothTranslationsWhenKhmerProvided() {
        AdminIngredientRequest request = new AdminIngredientRequest(
                "Lemongrass", "ស្លឹកគ្រៃ", "vegetable", "stalk", "Fresh lemongrass stalk", "ស្លឹកគ្រៃស្រស់", null);

        when(ingredientRepository.findByIngredientNameIgnoreCase("Lemongrass")).thenReturn(Optional.empty());
        when(ingredientRepository.save(any(Ingredient.class))).thenAnswer(invocation -> {
            Ingredient ing = invocation.getArgument(0);
            ing.setIngredientId(15);
            return ing;
        });

        IngredientTranslation kmTrans = new IngredientTranslation();
        kmTrans.setLanguageCode("km");
        kmTrans.setName("ស្លឹកគ្រៃ");
        kmTrans.setDescription("ស្លឹកគ្រៃស្រស់");
        when(ingredientTranslationRepository.findByIngredientIngredientIdAndLanguageCode(15, "km"))
                .thenReturn(Optional.of(kmTrans));

        AdminIngredientDto result = service.create(request);

        assertNotNull(result);
        assertEquals(15, result.ingredientId());
        assertEquals("Lemongrass", result.ingredientName());
        assertEquals("ស្លឹកគ្រៃ", result.ingredientNameKm());
        assertEquals("Fresh lemongrass stalk", result.description());
        assertEquals("ស្លឹកគ្រៃស្រស់", result.descriptionKm());

        ArgumentCaptor<IngredientTranslation> captor = ArgumentCaptor.forClass(IngredientTranslation.class);
        verify(ingredientTranslationRepository, times(2)).save(captor.capture());

        List<IngredientTranslation> saved = captor.getAllValues();
        assertEquals("en", saved.get(0).getLanguageCode());
        assertEquals("Lemongrass", saved.get(0).getName());
        assertEquals("km", saved.get(1).getLanguageCode());
        assertEquals("ស្លឹកគ្រៃ", saved.get(1).getName());
    }

    @Test
    void update_UpdatesKhmerTranslation() {
        Ingredient existing = new Ingredient();
        existing.setIngredientId(8);
        existing.setIngredientName("Garlic");
        existing.setIngredientType("spice");
        existing.setDefaultUnit("clove");

        when(ingredientRepository.findById(8)).thenReturn(Optional.of(existing));
        when(ingredientRepository.findByIngredientNameIgnoreCase("Garlic")).thenReturn(Optional.of(existing));
        when(ingredientRepository.save(any(Ingredient.class))).thenAnswer(i -> i.getArgument(0));

        IngredientTranslation enTrans = new IngredientTranslation();
        enTrans.setIngredient(existing);
        enTrans.setLanguageCode("en");
        enTrans.setName("Garlic");
        when(ingredientTranslationRepository.findByIngredientIngredientIdAndLanguageCode(8, "en"))
                .thenReturn(Optional.of(enTrans));

        IngredientTranslation kmTrans = new IngredientTranslation();
        kmTrans.setIngredient(existing);
        kmTrans.setLanguageCode("km");
        kmTrans.setName("ខ្ទឹមស");
        when(ingredientTranslationRepository.findByIngredientIngredientIdAndLanguageCode(8, "km"))
                .thenReturn(Optional.of(kmTrans));

        AdminIngredientRequest request = new AdminIngredientRequest(
                "Garlic", "ខ្ទឹមសស្រស់", "spice", "clove", "Fresh garlic", "ខ្ទឹមសស្រស់ល្អ", null);

        AdminIngredientDto result = service.update(8, request);

        assertEquals("Garlic", result.ingredientName());
        assertEquals("ខ្ទឹមសស្រស់", kmTrans.getName());
        assertEquals("ខ្ទឹមសស្រស់ល្អ", kmTrans.getDescription());
        verify(ingredientTranslationRepository, times(2)).save(any(IngredientTranslation.class));
    }

    @Test
    void delete_DeletesTranslationsAndIngredientWhenNotReferenced() {
        Ingredient existing = new Ingredient();
        existing.setIngredientId(8);
        when(ingredientRepository.findById(8)).thenReturn(Optional.of(existing));

        Query mockQuery = mock(Query.class);
        when(entityManager.createNativeQuery(any(String.class))).thenReturn(mockQuery);
        when(mockQuery.setParameter(eq("ingredientId"), eq(8))).thenReturn(mockQuery);
        when(mockQuery.getSingleResult()).thenReturn(0L);

        IngredientTranslation enTrans = new IngredientTranslation();
        IngredientTranslation kmTrans = new IngredientTranslation();
        when(ingredientTranslationRepository.findByIngredientIngredientIdAndLanguageCode(8, "en"))
                .thenReturn(Optional.of(enTrans));
        when(ingredientTranslationRepository.findByIngredientIngredientIdAndLanguageCode(8, "km"))
                .thenReturn(Optional.of(kmTrans));

        service.delete(8);

        verify(ingredientTranslationRepository).delete(enTrans);
        verify(ingredientTranslationRepository).delete(kmTrans);
        verify(ingredientRepository).delete(existing);
    }

    @Test
    void delete_ThrowsWhenIngredientUsedInMeals() {
        Ingredient existing = new Ingredient();
        existing.setIngredientId(8);
        when(ingredientRepository.findById(8)).thenReturn(Optional.of(existing));

        Query mockQuery = mock(Query.class);
        when(entityManager.createNativeQuery(any(String.class))).thenReturn(mockQuery);
        when(mockQuery.setParameter(eq("ingredientId"), eq(8))).thenReturn(mockQuery);
        when(mockQuery.getSingleResult()).thenReturn(3L);

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> service.delete(8));
        assertEquals("This ingredient is used by meals and cannot be deleted", ex.getMessage());
    }
}
