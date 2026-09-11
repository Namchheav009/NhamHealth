package com.nhamhealth.nhamhealth_api.service.meal;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import java.math.BigDecimal;
import java.util.*;
import org.junit.jupiter.api.*;
import org.mockito.ArgumentCaptor;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.util.ReflectionTestUtils;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.nhamhealth.nhamhealth_api.dto.request.*;
import com.nhamhealth.nhamhealth_api.dto.response.MealAdminRowDto;
import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.repository.catalog.*;
import com.nhamhealth.nhamhealth_api.repository.meal.*;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;
import com.nhamhealth.nhamhealth_api.repository.translation.MealCategoryTranslationRepository;
import jakarta.persistence.*;
import jakarta.validation.*;

class ScrapedMealImportServiceTests {
    private final MealCategoryRepository categories = mock(MealCategoryRepository.class);
    private final MealCategoryTranslationRepository categoryTranslations = mock(MealCategoryTranslationRepository.class);
    private final IngredientRepository ingredients = mock(IngredientRepository.class);
    private final NutrientRepository nutrients = mock(NutrientRepository.class);
    private final MealNutritionRepository nutrition = mock(MealNutritionRepository.class);
    private final MealRepository meals = mock(MealRepository.class);
    private final MealAdminService admin = mock(MealAdminService.class);
    private final ProfileImageStorageService images = mock(ProfileImageStorageService.class);
    private final EntityManager em = mock(EntityManager.class);
    private final Query nativeQuery = mock(Query.class);
    private ValidatorFactory factory;
    private ScrapedMealImportService service;
    private final MockMultipartFile photo = new MockMultipartFile("image", "meal.webp", "image/webp", new byte[]{1});
    private static final String PAYLOAD = """
        {"mealName":"Test meal","categoryName":"Breakfast","categoryNameKm":"អាហារពេលព្រឹក",
         "calories":500,"proteinGrams":25,"servings":4,
         "difficulty":"EASY","cookingTimeMinutes":20,"nutritionBasis":"UNKNOWN",
         "ingredients":[{"ingredientName":"Pork","quantity":600,"unit":"g","displayOrder":1}],
         "steps":[{"stepNumber":1,"instruction":"Cook the ingredients."}],
         "sourceLanguage":"en","sourceName":"Test source","sourceUrl":"https://example.com/recipe/",
         "scrapedAt":"2026-09-08T00:00:00Z","published":true,"reviewStatus":"APPROVED"}
        """;

    @BeforeEach void setup() {
        factory = Validation.buildDefaultValidatorFactory();
        service = new ScrapedMealImportService(factory.getValidator(), categories, categoryTranslations, ingredients, nutrients,
                nutrition, meals, admin, images, em);
        when(em.createNativeQuery(anyString())).thenReturn(nativeQuery);
        when(nativeQuery.setParameter(anyString(), any())).thenReturn(nativeQuery);
        when(nativeQuery.getResultList()).thenReturn(List.of());
        Query names = mock(Query.class);
        when(em.createQuery(anyString())).thenReturn(names);
        when(names.setParameter(anyString(), any())).thenReturn(names);
        when(names.getResultList()).thenReturn(List.of());
        MealCategory category = new MealCategory();
        category.setIsActive(true);
        ReflectionTestUtils.setField(category, "categoryId", 1);
        when(categories.findByCategoryNameIgnoreCase("Breakfast")).thenReturn(Optional.of(category));
        Ingredient ingredient = new Ingredient();
        ReflectionTestUtils.setField(ingredient, "ingredientId", 2);
        when(ingredients.findByIngredientNameIgnoreCase("Pork")).thenReturn(Optional.of(ingredient));
        when(images.storeMealImage(photo)).thenReturn("https://storage.example/meal.webp");
        when(admin.createScrapedDraft(any())).thenReturn(new MealAdminRowDto(7, null, null, null,
                "Test meal", null, null, null, List.of(), 0, null, null));
        when(meals.findById(7)).thenReturn(Optional.of(new Meal()));
    }

    @AfterEach void close() { factory.close(); }

    @Test void importsAsDraftAndPreservesSourceEvenIfCallerRequestsPublication() {
        var result = service.importMeal(PAYLOAD, photo);
        var request = ArgumentCaptor.forClass(AdminMealRequest.class);
        verify(admin).createScrapedDraft(request.capture());
        assertFalse(request.getValue().published());
        assertNull(request.getValue().calories());
        assertEquals(2, request.getValue().ingredients().getFirst().ingredientId());
        assertEquals("PENDING_REVIEW", result.get("reviewStatus"));
        assertEquals(false, result.get("published"));
        verify(nativeQuery).setParameter("payload", PAYLOAD);
        verifyNoInteractions(nutrition);
    }

    @Test void missingIngredientsAreCreatedAndMarkedForCatalogReview() {
        when(ingredients.findByIngredientNameIgnoreCase("Pork")).thenReturn(Optional.empty());
        when(ingredients.save(any(Ingredient.class))).thenAnswer(call -> {
            Ingredient created = call.getArgument(0);
            ReflectionTestUtils.setField(created, "ingredientId", 9);
            return created;
        });

        var result = service.importMeal(PAYLOAD, photo);

        var created = ArgumentCaptor.forClass(Ingredient.class);
        verify(ingredients).save(created.capture());
        assertEquals("Pork", created.getValue().getIngredientName());
        assertEquals("SCRAPED_PENDING_REVIEW", created.getValue().getIngredientType());
        assertEquals("g", created.getValue().getDefaultUnit());
        assertTrue(((List<?>) result.get("warnings")).stream()
                .anyMatch(warning -> warning.toString().contains("Pork")));
        var request = ArgumentCaptor.forClass(AdminMealRequest.class);
        verify(admin).createScrapedDraft(request.capture());
        assertEquals(9, request.getValue().ingredients().getFirst().ingredientId());
    }

    @Test void repeatedIngredientsWithTheSameUnitAreCombined() {
        String duplicate = PAYLOAD.replace(
                "\"ingredients\":[{\"ingredientName\":\"Pork\",\"quantity\":600,\"unit\":\"g\",\"displayOrder\":1}]",
                "\"ingredients\":[{\"ingredientName\":\"Pork\",\"quantity\":600,\"unit\":\"g\",\"displayOrder\":1},"
                        + "{\"ingredientName\":\"Pork\",\"quantity\":400,\"unit\":\"g\",\"displayOrder\":2}]");

        var result = service.importMeal(duplicate, photo);

        var request = ArgumentCaptor.forClass(AdminMealRequest.class);
        verify(admin).createScrapedDraft(request.capture());
        assertEquals(1, request.getValue().ingredients().size());
        assertEquals(new BigDecimal("1000"), request.getValue().ingredients().getFirst().quantity());
        assertTrue(((List<?>) result.get("warnings")).stream()
                .anyMatch(warning -> warning.toString().contains("Combined repeated ingredient")));
    }

    @Test void missingStepsFailBeforeAnyDatabaseOrStorageWork() {
        String invalid = PAYLOAD.replace("[{\"stepNumber\":1,\"instruction\":\"Cook the ingredients.\"}]", "[]");
        assertThrows(IllegalArgumentException.class, () -> service.importMeal(invalid, photo));
        verifyNoInteractions(em, images, admin);
    }

    @Test void duplicateSourceDoesNotUpload() {
        when(nativeQuery.getResultList()).thenReturn(List.of(7));
        assertThrows(org.springframework.web.server.ResponseStatusException.class, () -> service.importMeal(PAYLOAD, photo));
        verifyNoInteractions(images, admin);
    }

    @Test void missingPhotoCreatesUnpublishedDraftWithoutStorageUpload() {
        var result = service.importMeal(PAYLOAD, null);
        assertNull(result.get("mainImageUrl"));
        assertEquals(false, result.get("published"));
        verifyNoInteractions(images);
        var request = ArgumentCaptor.forClass(AdminMealRequest.class);
        verify(admin).createScrapedDraft(request.capture());
        assertNull(request.getValue().mainImageUrl());
        assertFalse(request.getValue().published());
    }

    @Test void convertsOnlyKnownNutritionBasis() throws Exception {
        var mapper = new ObjectMapper();
        var whole = mapper.readValue(PAYLOAD.replace("UNKNOWN", "WHOLE_RECIPE"), ScrapedMealImportRequest.class);
        assertEquals(new BigDecimal("100.0000"), ScrapedMealImportService.perServing(new BigDecimal("400"), whole));
        var unknown = mapper.readValue(PAYLOAD, ScrapedMealImportRequest.class);
        assertNull(ScrapedMealImportService.perServing(new BigDecimal("400"), unknown));
        var per100 = mapper.readValue(PAYLOAD.replace("UNKNOWN", "PER_100G"), ScrapedMealImportRequest.class);
        assertNull(ScrapedMealImportService.perServing(new BigDecimal("400"), per100));
    }

    @Test void normalizesSourceAndRejectsNonHttpUrls() {
        assertEquals("https://example.com/recipe", ScrapedMealImportService.canonicalSourceUrl("https://EXAMPLE.com/recipe/#top"));
        assertThrows(IllegalArgumentException.class, () -> ScrapedMealImportService.canonicalSourceUrl("file:///tmp/recipe"));
    }

    @Test void missingCaloriesAndProteinSucceedsValidation() {
        String withoutNutrition = PAYLOAD.replace("\"calories\":500,", "").replace("\"proteinGrams\":25,", "");
        var result = service.importMeal(withoutNutrition, photo);
        assertNotNull(result.get("mealId"));
    }

    @Test void negativeCaloriesFailsValidation() {
        String invalid = PAYLOAD.replace("\"calories\":500,", "\"calories\":-10,");
        assertThrows(IllegalArgumentException.class, () -> service.importMeal(invalid, photo));
    }

    @Test void negativeProteinFailsValidation() {
        String invalid = PAYLOAD.replace("\"proteinGrams\":25,", "\"proteinGrams\":-5,");
        assertThrows(IllegalArgumentException.class, () -> service.importMeal(invalid, photo));
    }
}
