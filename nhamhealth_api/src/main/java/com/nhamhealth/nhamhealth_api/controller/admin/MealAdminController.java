package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.multipart.MultipartFile;

import com.nhamhealth.nhamhealth_api.dto.response.MealAdminRowDto;
import com.nhamhealth.nhamhealth_api.dto.request.AdminMealRequest;
import com.nhamhealth.nhamhealth_api.service.MealAdminService;
import com.nhamhealth.nhamhealth_api.service.ProfileImageStorageService;

@Controller
public class MealAdminController {

    private final MealAdminService mealAdminService;
    private final ProfileImageStorageService profileImageStorageService;

    public MealAdminController(MealAdminService mealAdminService, ProfileImageStorageService profileImageStorageService) {
        this.mealAdminService = mealAdminService;
        this.profileImageStorageService = profileImageStorageService;
    }

    @GetMapping("/admin/meals")
    public String mealsPage(Authentication authentication, Model model) {
        model.addAttribute("pageTitle", "Meals");
        model.addAttribute("activePage", "meals");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("mealCategories", mealAdminService.getActiveCategories());
        model.addAttribute("mealTags", mealAdminService.getMealTags());
        model.addAttribute("mealTotal", mealAdminService.getMealCount());
        return "admin/meals";
    }

    @GetMapping("/admin/meals/data")
    @ResponseBody
    public ResponseEntity<Page<MealAdminRowDto>> listMeals(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String status,
            @RequestParam(required = false) String tag) {
        PageRequest pageRequest = PageRequest.of(Math.max(page, 0), 10, Sort.by(Sort.Direction.DESC, "updatedAt"));
        return ResponseEntity.ok(mealAdminService.getMealsForAdmin(search, category, status, tag, pageRequest));
    }

    @PostMapping("/admin/meals")
    @ResponseBody
    public ResponseEntity<?> createMeal(@jakarta.validation.Valid @RequestBody AdminMealRequest request) {
        try {
            return ResponseEntity.status(org.springframework.http.HttpStatus.CREATED).body(mealAdminService.createMeal(request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @GetMapping("/admin/meals/{mealId}")
    @ResponseBody
    public ResponseEntity<?> getMeal(@PathVariable Integer mealId) {
        try {
            return ResponseEntity.ok(mealAdminService.getMealForEdit(mealId));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.notFound().build();
        }
    }

    @PutMapping("/admin/meals/{mealId}")
    @ResponseBody
    public ResponseEntity<?> updateMeal(
            @PathVariable Integer mealId,
            @jakarta.validation.Valid @RequestBody AdminMealRequest request) {
        try {
            return ResponseEntity.ok(mealAdminService.updateMeal(mealId, request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @DeleteMapping("/admin/meals/{mealId}")
    @ResponseBody
    public ResponseEntity<?> deleteMeal(@PathVariable Integer mealId) {
        try {
            mealAdminService.deleteMeal(mealId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(org.springframework.http.HttpStatus.NOT_FOUND)
                    .body(Map.of("message", exception.getMessage()));
        }
    }

    @PostMapping(value = "/admin/meal-images", consumes = "multipart/form-data")
    @ResponseBody
    public ResponseEntity<?> uploadMealImage(@RequestParam("file") MultipartFile file) {
        try {
            return ResponseEntity.ok(Map.of("mainImageUrl", profileImageStorageService.storeMealImage(file)));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        } catch (IllegalStateException exception) {
            return ResponseEntity.internalServerError().body(Map.of("message", exception.getMessage()));
        }
    }

    @PostMapping(value = "/admin/recipe-step-images", consumes = "multipart/form-data")
    @ResponseBody
    public ResponseEntity<?> uploadRecipeStepImage(@RequestParam("file") MultipartFile file) {
        try {
            return ResponseEntity.ok(Map.of("imageUrl", profileImageStorageService.storeRecipeStepImage(file)));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        } catch (IllegalStateException exception) {
            return ResponseEntity.internalServerError().body(Map.of("message", exception.getMessage()));
        }
    }
}
