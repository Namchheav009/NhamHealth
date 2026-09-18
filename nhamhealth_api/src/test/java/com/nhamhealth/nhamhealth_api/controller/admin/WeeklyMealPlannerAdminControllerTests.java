package com.nhamhealth.nhamhealth_api.controller.admin;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;

@ActiveProfiles("test")
@SpringBootTest
@AutoConfigureMockMvc
class WeeklyMealPlannerAdminControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private WeeklyMealRecommendationRepository recommendations;

    @MockitoBean
    private PlannerMealRepository plannerMeals;

    @MockitoBean
    private MealCategoryRepository mealCategories;

    @MockitoBean
    private ProfileImageStorageService profileImageStorageService;

    @Test
    void pageRendersSuccessfullyWithKhmerFields() throws Exception {
        MealCategory category = new MealCategory();
        category.setCategoryId(1);
        category.setCategoryName("Breakfast");
        category.setSortOrder(1);
        category.setIsActive(true);

        PlannerMeal meal = new PlannerMeal();
        meal.setPlannerMealId(1);
        meal.setNameEn("Oatmeal with Fruits");
        meal.setNameKm("ស្រូវអូតជាមួយផ្លែឈើ");
        meal.setCategory(category);
        meal.setCategoryEn("Breakfast");
        meal.setCategoryKm("អាហារពេលព្រឹក");
        meal.setDescriptionEn("Healthy oats");
        meal.setDescriptionKm("ស្រូវអូតសុខភាព");
        meal.setCalories(new BigDecimal("350.00"));
        meal.setProteinGrams(new BigDecimal("12.00"));
        meal.setCarbsGrams(new BigDecimal("55.00"));
        meal.setFatGrams(new BigDecimal("6.00"));
        meal.setCookingTimeMinutes(15);
        meal.setIngredientsText("Oats | 50 | g");
        meal.setIngredientsTextKm("ស្រូវអូត | 50 | g");
        meal.setInstructionsText("Boil water and cook oats");
        meal.setInstructionsTextKm("ដាំទឹក រួចស្ងោរស្រូវអូត");
        meal.setTagsText("Healthy, Oats");
        meal.setTagsTextKm("សុខភាព, ស្រូវអូត");
        meal.setActive(true);

        WeeklyMealRecommendation rec = new WeeklyMealRecommendation();
        org.springframework.test.util.ReflectionTestUtils.setField(rec, "recommendationId", 10);
        rec.setDayOfWeek("MONDAY");
        rec.setMealSlot("BREAKFAST");
        rec.setPlannerMeal(meal);
        rec.setSortOrder(1);
        rec.setActive(true);
        rec.setCreatedAt(LocalDateTime.now());
        rec.setUpdatedAt(LocalDateTime.now());

        when(recommendations.findAllByOrderBySortOrderAscRecommendationIdAsc()).thenReturn(List.of(rec));
        when(plannerMeals.findAllByOrderByNameEnAsc()).thenReturn(List.of(meal));
        when(mealCategories.findAllByIsActiveTrueOrderBySortOrderAsc()).thenReturn(List.of(category));

        mockMvc.perform(get("/admin/meal-planner").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/meal-planner"))
                .andExpect(content().string(containsString("Ingredients list (Khmer)")))
                .andExpect(content().string(containsString("Preparation / cooking steps (Khmer)")))
                .andExpect(content().string(containsString("Tags (Khmer)")))
                .andExpect(content().string(containsString("data-ingredients-km=")))
                .andExpect(content().string(containsString("data-instructions-km=")))
                .andExpect(content().string(containsString("data-tags-km=")));
    }
}
