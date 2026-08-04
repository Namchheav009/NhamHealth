package com.nhamhealth.nhamhealth_api.controller;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.MealFavorite;
import com.nhamhealth.nhamhealth_api.entity.PostFavorite;
import com.nhamhealth.nhamhealth_api.repository.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.PostFavoriteRepository;

@Controller
public class FavoritesAdminController {

    private final MealFavoriteRepository mealFavoriteRepository;
    private final PostFavoriteRepository postFavoriteRepository;

    public FavoritesAdminController(MealFavoriteRepository mealFavoriteRepository,
            PostFavoriteRepository postFavoriteRepository) {
        this.mealFavoriteRepository = mealFavoriteRepository;
        this.postFavoriteRepository = postFavoriteRepository;
    }

    @GetMapping("/admin/favorites")
    public String listFavorites(Model model) {
        List<MealFavorite> foodFavorites = mealFavoriteRepository.findAllByOrderBySavedAtDesc();
        List<PostFavorite> postFavorites = postFavoriteRepository.findAllByOrderBySavedAtDesc();

        long totalFood = foodFavorites.size();
        long totalPost = postFavorites.size();

        Set<Integer> uniqueFoodUsers = foodFavorites.stream()
                .map(f -> f.getUser().getUserId())
                .collect(Collectors.toSet());

        model.addAttribute("pageTitle", "Favorites");
        model.addAttribute("foodFavorites", foodFavorites);
        model.addAttribute("postFavorites", postFavorites);
        model.addAttribute("totalFoodFavorites", totalFood);
        model.addAttribute("totalPostFavorites", totalPost);
        model.addAttribute("usersWithFoodFavorites", uniqueFoodUsers.size());

        return "admin/favorite";
    }
}
