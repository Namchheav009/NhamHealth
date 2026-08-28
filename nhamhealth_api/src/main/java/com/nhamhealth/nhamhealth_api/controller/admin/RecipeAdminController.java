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
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.service.MealAdminService;
import com.nhamhealth.nhamhealth_api.service.RecipeFlowService;

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
        return "admin/community-recipes";
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
