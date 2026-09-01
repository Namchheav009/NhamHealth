package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.meal.MealAdminService;
import com.nhamhealth.nhamhealth_api.service.recipe.RecipeFlowService;

@Controller
public class RecipeAdminController {
    private final RecipeFlowService recipes;
    private final MealAdminService meals;
    private final UserRepository users;
    public RecipeAdminController(RecipeFlowService recipes, MealAdminService meals, UserRepository users) {
        this.recipes = recipes; this.meals = meals; this.users = users;
    }
    @GetMapping("/admin/community-recipes")
    public String page(Authentication authentication, Model model) {
        model.addAttribute("pageTitle", "Community Recipes"); model.addAttribute("activePage", "community-recipes");
        model.addAttribute("adminName", authentication.getName()); model.addAttribute("recipes", recipes.adminRecipes());
        model.addAttribute("mealCategories", meals.getActiveCategories());
        model.addAttribute("users", users.findAll());
        return "admin/community-recipes";
    }
    public record MealPostRequest(Integer authorId, String recipeName, String description,
            Integer cookingTimeMinutes, Integer servings, String difficulty, String status) { }

    @PostMapping("/admin/community-recipes") @ResponseBody
    public ResponseEntity<?> create(@RequestBody MealPostRequest request) {
        try {
            validate(request, true);
            return ResponseEntity.ok(recipes.adminCreate(request.authorId(), request.recipeName(), request.description(),
                    request.cookingTimeMinutes(), request.servings(), request.difficulty(), request.status()));
        } catch (Exception exception) { return badRequest(exception, "Unable to create this meal post."); }
    }

    @PutMapping("/admin/community-recipes/{recipeId}") @ResponseBody
    public ResponseEntity<?> update(@PathVariable Integer recipeId, @RequestBody MealPostRequest request) {
        try {
            validate(request, false);
            return ResponseEntity.ok(recipes.adminUpdate(recipeId, request.recipeName(), request.description(),
                    request.cookingTimeMinutes(), request.servings(), request.difficulty(), request.status()));
        } catch (Exception exception) { return badRequest(exception, "Unable to update this meal post."); }
    }

    @DeleteMapping("/admin/community-recipes/{recipeId}") @ResponseBody
    public ResponseEntity<?> delete(@PathVariable Integer recipeId) {
        try { recipes.adminDelete(recipeId); return ResponseEntity.noContent().build(); }
        catch (Exception exception) { return badRequest(exception, "Unable to delete this meal post."); }
    }

    private static void validate(MealPostRequest request, boolean requireAuthor) {
        if (request == null || request.recipeName() == null || request.recipeName().isBlank())
            throw new IllegalArgumentException("Meal post name is required.");
        if (request.recipeName().trim().length() > 150)
            throw new IllegalArgumentException("Meal post name must be 150 characters or fewer.");
        if (requireAuthor && request.authorId() == null) throw new IllegalArgumentException("Select an author.");
        if (request.cookingTimeMinutes() != null && request.cookingTimeMinutes() < 1)
            throw new IllegalArgumentException("Cooking time must be positive.");
        if (request.servings() != null && request.servings() < 1)
            throw new IllegalArgumentException("Servings must be positive.");
    }

    private static ResponseEntity<?> badRequest(Exception exception, String fallback) {
        String message = exception.getMessage();
        return ResponseEntity.badRequest().body(Map.of("message", message == null || message.isBlank() ? fallback : message));
    }
    @PostMapping("/admin/community-recipes/{recipeId}/promote") @ResponseBody
    public ResponseEntity<?> promote(Authentication authentication, @PathVariable Integer recipeId, @RequestParam Integer categoryId) {
        try {
            Integer adminId = users.findByEmailIgnoreCase(authentication.getName()).orElseThrow().getUserId();
            return ResponseEntity.ok(recipes.promote(recipeId, categoryId, adminId));
        } catch (IllegalArgumentException exception) { return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage())); }
        catch (Exception exception) { return ResponseEntity.badRequest().body(Map.of("message", "Unable to promote this recipe.")); }
    }
}
