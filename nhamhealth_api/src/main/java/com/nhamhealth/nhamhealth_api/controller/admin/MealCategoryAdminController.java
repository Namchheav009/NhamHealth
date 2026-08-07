package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.validation.Valid;

import com.nhamhealth.nhamhealth_api.dto.request.AdminMealCategoryRequest;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.repository.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.service.MealCategoryAdminService;

@Controller
public class MealCategoryAdminController {

    private final MealCategoryRepository mealCategoryRepository;
    private final MealRepository mealRepository;
    private final MealCategoryAdminService mealCategoryAdminService;

    public MealCategoryAdminController(
            MealCategoryRepository mealCategoryRepository,
            MealRepository mealRepository,
            MealCategoryAdminService mealCategoryAdminService) {
        this.mealCategoryRepository = mealCategoryRepository;
        this.mealRepository = mealRepository;
        this.mealCategoryAdminService = mealCategoryAdminService;
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

    @PostMapping("/admin/meal-categories")
    @ResponseBody
    public ResponseEntity<?> createCategory(@Valid @RequestBody AdminMealCategoryRequest request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(mealCategoryAdminService.create(request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @PutMapping("/admin/meal-categories/{categoryId}")
    @ResponseBody
    public ResponseEntity<?> updateCategory(
            @PathVariable Integer categoryId,
            @Valid @RequestBody AdminMealCategoryRequest request) {
        try {
            return ResponseEntity.ok(mealCategoryAdminService.update(categoryId, request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @DeleteMapping("/admin/meal-categories/{categoryId}")
    @ResponseBody
    public ResponseEntity<?> deleteCategory(@PathVariable Integer categoryId) {
        try {
            mealCategoryAdminService.delete(categoryId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }
}
