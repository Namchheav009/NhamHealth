package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.repository.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;

@Controller
public class MealCategoryAdminController {

    private final MealCategoryRepository mealCategoryRepository;
    private final MealRepository mealRepository;

    public MealCategoryAdminController(
            MealCategoryRepository mealCategoryRepository,
            MealRepository mealRepository) {
        this.mealCategoryRepository = mealCategoryRepository;
        this.mealRepository = mealRepository;
    }

    @GetMapping("/admin/meal-categories")
    public String mealCategories(Authentication authentication, Model model) {
        List<MealCategory> categories = mealCategoryRepository.findAllByOrderBySortOrderAsc();
        Map<Integer, Long> mealCounts = new HashMap<>();

        for (MealCategory category : categories) {
            long count = mealRepository.countByCategoryCategoryId(category.getCategoryId());
            mealCounts.put(category.getCategoryId(), count);
        }

        model.addAttribute("pageTitle", "Meal Categories");
        model.addAttribute("activePage", "meal-categories");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("mealCategories", categories);
        model.addAttribute("mealCounts", mealCounts);
        model.addAttribute("totalCategories", categories.size());
        model.addAttribute("totalMeals", mealRepository.count());
        return "admin/meal-categories";
    }
}
