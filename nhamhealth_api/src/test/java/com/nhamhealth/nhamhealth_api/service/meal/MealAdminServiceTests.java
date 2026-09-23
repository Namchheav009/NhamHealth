package com.nhamhealth.nhamhealth_api.service.meal;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.request.AdminMealIngredientRequest;
import com.nhamhealth.nhamhealth_api.dto.request.AdminMealRequest;
import com.nhamhealth.nhamhealth_api.dto.request.AdminRecipeStepRequest;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.*;
import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeStepRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.*;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;

import jakarta.persistence.EntityManager;

class MealAdminServiceTests {

    private MealRepository mealRepository;
    private MealCategoryRepository mealCategoryRepository;
    private MealAdminService service;

    @BeforeEach
    void setUp() {
        mealRepository = mock(MealRepository.class);
        MealTagRepository mealTagRepository = mock(MealTagRepository.class);
        MealFavoriteRepository mealFavoriteRepository = mock(MealFavoriteRepository.class);
        mealCategoryRepository = mock(MealCategoryRepository.class);
        RecipeStepRepository recipeStepRepository = mock(RecipeStepRepository.class);
        IngredientRepository ingredientRepository = mock(IngredientRepository.class);
        MealIngredientRepository mealIngredientRepository = mock(MealIngredientRepository.class);
        MealNutritionRepository mealNutritionRepository = mock(MealNutritionRepository.class);
        ProfileImageStorageService profileImageStorageService = mock(ProfileImageStorageService.class);
        EntityManager entityManager = mock(EntityManager.class);
        MealTranslationRepository mealTranslations = mock(MealTranslationRepository.class);
        IngredientTranslationRepository ingredientTranslations = mock(IngredientTranslationRepository.class);
        MealIngredientTranslationRepository mealIngredientTranslations = mock(MealIngredientTranslationRepository.class);
        RecipeStepTranslationRepository recipeStepTranslations = mock(RecipeStepTranslationRepository.class);

        when(profileImageStorageService.isStoredMealImageUrl(any())).thenAnswer(inv -> {
            String url = inv.getArgument(0);
            return url != null && !url.isBlank();
        });

        service = new MealAdminService(
                mealRepository,
                mealTagRepository,
                mealFavoriteRepository,
                mealCategoryRepository,
                recipeStepRepository,
                ingredientRepository,
                mealIngredientRepository,
                mealNutritionRepository,
                profileImageStorageService,
                entityManager,
                mealTranslations,
                ingredientTranslations,
                mealIngredientTranslations,
                recipeStepTranslations
        );
    }

    @Test
    void cannotPublishRecipeWithoutCookingTime() {
        MealCategory category = new MealCategory();
        when(mealCategoryRepository.findById(1)).thenReturn(Optional.of(category));

        AdminMealRequest request = new AdminMealRequest(
                "Amok", "អាម៉ុក", 1, BigDecimal.valueOf(350), 4,
                "Tasty Amok", "អាម៉ុកឆ្ងាញ់", "MEDIUM",
                null, // missing cooking time
                15, 0, 15, false,
                true, // attempting to publish
                "https://storage.example/amok.webp",
                List.of(new AdminMealIngredientRequest(1, BigDecimal.valueOf(500), "g", "sliced", "ត្រី", "ហាន់")),
                List.of(new AdminRecipeStepRequest("Cook steam amok.", "ចំហុយអាម៉ុក"))
        );

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> service.createMeal(request));
        assertTrue(ex.getMessage().contains("Cooking time is required before publishing a meal"));
    }

    @Test
    void cannotPublishRecipeWithoutMealImage() {
        MealCategory category = new MealCategory();
        when(mealCategoryRepository.findById(1)).thenReturn(Optional.of(category));

        AdminMealRequest request = new AdminMealRequest(
                "Amok", "អាម៉ុក", 1, BigDecimal.valueOf(350), 4,
                "Tasty Amok", "អាម៉ុកឆ្ងាញ់", "MEDIUM",
                30,
                15, 0, 45, false,
                true, // attempting to publish
                null, // missing meal image
                List.of(new AdminMealIngredientRequest(1, BigDecimal.valueOf(500), "g", "sliced", "ត្រី", "ហាន់")),
                List.of(new AdminRecipeStepRequest("Cook steam amok.", "ចំហុយអាម៉ុក"))
        );

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> service.createMeal(request));
        assertTrue(ex.getMessage().contains("meal image"));
    }

    @Test
    void createScrapedDraftRejectsPublishedRequest() {
        AdminMealRequest request = new AdminMealRequest(
                "Amok", "អាម៉ុក", 1, BigDecimal.valueOf(350), 4,
                "Tasty Amok", "អាម៉ុកឆ្ងាញ់", "MEDIUM",
                30, 15, 0, 45, false,
                true, // published
                "https://storage.example/amok.webp",
                List.of(), List.of()
        );
        assertThrows(IllegalArgumentException.class, () -> service.createScrapedDraft(request));
    }

    @Test
    void createScrapedDraftForcesUnpublished() {
        MealCategory category = new MealCategory();
        when(mealCategoryRepository.findById(1)).thenReturn(Optional.of(category));
        when(mealRepository.save(any(Meal.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AdminMealRequest draftRequest = new AdminMealRequest(
                "Bai Sach Chrouk", "បាយសាច់ជ្រូក", 1, BigDecimal.valueOf(450), 2,
                "Breakfast pork", "បាយសាច់ជ្រូកពេលព្រឹក", "EASY",
                null, // no cooking time initially
                10, 0, 10, true,
                false, // draft
                null, // no image initially
                List.of(),
                List.of()
        );

        var row = service.createScrapedDraft(draftRequest);
        assertNotNull(row);
        verify(mealRepository).save(argThat(meal -> Boolean.FALSE.equals(meal.getIsPublished())));
    }
}
