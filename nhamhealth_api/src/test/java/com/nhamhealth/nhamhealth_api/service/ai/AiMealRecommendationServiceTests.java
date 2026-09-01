package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendation;
import com.nhamhealth.nhamhealth_api.entity.AiRecommendationItem;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;
import com.nhamhealth.nhamhealth_api.dto.ai.AiUserHealthProfile;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationItemRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyNutrientTotalRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.MoodRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

class AiMealRecommendationServiceTests {

    @Test
    void profileOnlyRecommendationUsesHeightWeightAndBmiContext() {
        AiRecommendationRepository recommendationRepository = mock(AiRecommendationRepository.class);
        AiRecommendationItemRepository itemRepository = mock(AiRecommendationItemRepository.class);
        MealRepository mealRepository = mock(MealRepository.class);
        MoodRepository moodRepository = mock(MoodRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        MealFavoriteRepository favoriteRepository = mock(MealFavoriteRepository.class);
        DailyWellnessSummaryRepository dailySummaryRepository = mock(DailyWellnessSummaryRepository.class);
        DailyNutrientTotalRepository dailyNutrientRepository = mock(DailyNutrientTotalRepository.class);
        AiUserHealthProfileService userHealthProfileService = mock(AiUserHealthProfileService.class);

        User user = new User();
        List<Meal> catalog = meals(4);
        when(userRepository.findById(9)).thenReturn(Optional.of(user));
        when(mealRepository.findAllByIsPublishedTrueOrderByMealNameAsc()).thenReturn(catalog);
        when(favoriteRepository.findAllByUserUserIdOrderBySavedAtDesc(9)).thenReturn(List.of());
        WellnessProfile wellnessProfile = new WellnessProfile();
        wellnessProfile.setHeightCm(BigDecimal.valueOf(165));
        wellnessProfile.setWeightKg(BigDecimal.valueOf(60));
        wellnessProfile.setActivityLevel("moderate");
        when(userHealthProfileService.load(9))
                .thenReturn(AiUserHealthProfile.from(9, wellnessProfile));
        when(dailySummaryRepository.findByUser_UserIdAndSummaryDate(any(), any()))
                .thenReturn(Optional.empty());

        AiMealRecommendationService service = service(
                recommendationRepository,
                itemRepository,
                mealRepository,
                moodRepository,
                userRepository,
                favoriteRepository,
                dailySummaryRepository,
                dailyNutrientRepository,
                userHealthProfileService);

        service.generate(9, null, true);

        ArgumentCaptor<AiRecommendation> recommendation = ArgumentCaptor.forClass(AiRecommendation.class);
        verify(recommendationRepository).saveAndFlush(recommendation.capture());
        assertNull(recommendation.getValue().getMood());
        assertTrue(recommendation.getValue().getRequestText().contains("BMI"));
        ArgumentCaptor<AiRecommendationItem> items = ArgumentCaptor.forClass(AiRecommendationItem.class);
        verify(itemRepository, times(4)).save(items.capture());
        assertTrue(items.getAllValues().stream()
                .allMatch(item -> item.getReasonText().contains("height 165 cm, weight 60 kg")));
    }

    @Test
    void fallbackReturnsFifteenDistinctMealsWhenCatalogHasEnoughMeals() {
        AiRecommendationRepository recommendationRepository = mock(AiRecommendationRepository.class);
        AiRecommendationItemRepository itemRepository = mock(AiRecommendationItemRepository.class);
        MealRepository mealRepository = mock(MealRepository.class);
        MoodRepository moodRepository = mock(MoodRepository.class);
        UserRepository userRepository = mock(UserRepository.class);
        MealFavoriteRepository favoriteRepository = mock(MealFavoriteRepository.class);
        DailyWellnessSummaryRepository dailySummaryRepository = mock(DailyWellnessSummaryRepository.class);
        DailyNutrientTotalRepository dailyNutrientRepository = mock(DailyNutrientTotalRepository.class);
        AiUserHealthProfileService userHealthProfileService = mock(AiUserHealthProfileService.class);

        User user = new User();
        Mood mood = new Mood();
        mood.setMoodName("Energetic");
        mood.setIsActive(true);
        List<Meal> catalog = meals(20);
        when(userRepository.findById(7)).thenReturn(Optional.of(user));
        when(moodRepository.findById(3)).thenReturn(Optional.of(mood));
        when(mealRepository.findAllByIsPublishedTrueOrderByMealNameAsc()).thenReturn(catalog);
        when(favoriteRepository.findAllByUserUserIdOrderBySavedAtDesc(7)).thenReturn(List.of());
        WellnessProfile wellnessProfile = new WellnessProfile();
        wellnessProfile.setHeightCm(BigDecimal.valueOf(172));
        wellnessProfile.setWeightKg(BigDecimal.valueOf(68));
        wellnessProfile.setActivityLevel("moderate");
        when(userHealthProfileService.load(7))
                .thenReturn(AiUserHealthProfile.from(7, wellnessProfile));
        when(dailySummaryRepository.findByUser_UserIdAndSummaryDate(any(), any()))
                .thenReturn(Optional.empty());

        AiMealRecommendationService service = service(
                recommendationRepository,
                itemRepository,
                mealRepository,
                moodRepository,
                userRepository,
                favoriteRepository,
                dailySummaryRepository,
                dailyNutrientRepository,
                userHealthProfileService);

        service.generate(7, 3, true);

        ArgumentCaptor<AiRecommendationItem> items = ArgumentCaptor.forClass(AiRecommendationItem.class);
        verify(itemRepository, times(15)).save(items.capture());
        assertEquals(15, items.getAllValues().size());
        assertEquals(15, new HashSet<>(items.getAllValues().stream()
                .map(item -> item.getMeal().getMealId()).toList()).size());
        assertEquals(
                java.util.stream.IntStream.rangeClosed(1, 15).boxed().toList(),
                items.getAllValues().stream().map(AiRecommendationItem::getRankOrder).toList());
        assertTrue(items.getAllValues().stream()
                .allMatch(item -> item.getReasonText() != null && !item.getReasonText().isBlank()));
        assertTrue(items.getAllValues().stream()
                .allMatch(item -> item.getReasonText().contains("height 172 cm, weight 68 kg")));
        verify(userHealthProfileService).load(7);
    }

    private AiMealRecommendationService service(
            AiRecommendationRepository recommendationRepository,
            AiRecommendationItemRepository itemRepository,
            MealRepository mealRepository,
            MoodRepository moodRepository,
            UserRepository userRepository,
            MealFavoriteRepository favoriteRepository,
            DailyWellnessSummaryRepository dailySummaryRepository,
            DailyNutrientTotalRepository dailyNutrientRepository,
            AiUserHealthProfileService userHealthProfileService) {
        return new AiMealRecommendationService(
                recommendationRepository,
                itemRepository,
                mealRepository,
                moodRepository,
                userRepository,
                favoriteRepository,
                dailySummaryRepository,
                dailyNutrientRepository,
                userHealthProfileService,
                "https://integrate.api.nvidia.com/v1",
                "",
                "nvidia/nemotron-3.5-lightning-30b-a3b",
                4096,
                1024);
    }

    private List<Meal> meals(int count) {
        List<Meal> meals = new ArrayList<>();
        for (int index = 1; index <= count; index++) {
            MealCategory category = mock(MealCategory.class);
            when(category.getCategoryId()).thenReturn((index - 1) % 5 + 1);
            when(category.getCategoryName()).thenReturn("Category " + ((index - 1) % 5 + 1));
            Meal meal = mock(Meal.class);
            when(meal.getMealId()).thenReturn(index);
            when(meal.getMealName()).thenReturn("Meal " + index);
            when(meal.getDescription()).thenReturn("Balanced meal " + index);
            when(meal.getCategory()).thenReturn(category);
            when(meal.getCaloriesCached()).thenReturn(BigDecimal.valueOf(300 + index * 10L));
            when(meal.getProteinGramsCached()).thenReturn(BigDecimal.valueOf(15 + index));
            when(meal.getCookingTimeMinutes()).thenReturn(15 + index);
            meals.add(meal);
        }
        return meals;
    }
}
