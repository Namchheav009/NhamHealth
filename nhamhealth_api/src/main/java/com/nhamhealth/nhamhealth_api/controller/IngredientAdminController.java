package com.nhamhealth.nhamhealth_api.controller;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.repository.IngredientRepository;

@Controller
public class IngredientAdminController {

    private final IngredientRepository ingredientRepository;

    public IngredientAdminController(IngredientRepository ingredientRepository) {
        this.ingredientRepository = ingredientRepository;
    }

    @GetMapping("/admin/ingredients")
    public String ingredients(Authentication authentication, Model model) {
        List<Ingredient> ingredients = ingredientRepository.findAllByOrderByIngredientNameAsc();

        List<Ingredient> recentIngredients = ingredients.stream()
                .sorted(Comparator.comparing(Ingredient::getIngredientName, Comparator.nullsLast(String::compareTo)))
                .collect(Collectors.toList());

        model.addAttribute("pageTitle", "Ingredients");
        model.addAttribute("activePage", "ingredients");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("ingredients", ingredients);
        model.addAttribute("recentIngredients", recentIngredients);
        model.addAttribute("totalIngredients", ingredientRepository.count());
        return "admin/ingredients";
    }
}
