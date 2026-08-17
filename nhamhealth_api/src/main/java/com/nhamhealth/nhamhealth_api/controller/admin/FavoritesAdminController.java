package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.stereotype.Controller;
import org.springframework.http.ResponseEntity;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import jakarta.validation.Valid;

import com.nhamhealth.nhamhealth_api.dto.request.AdminFavoriteRequest;
import com.nhamhealth.nhamhealth_api.entity.MealFavorite;
import com.nhamhealth.nhamhealth_api.entity.PostFavorite;
import com.nhamhealth.nhamhealth_api.repository.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.PostFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class FavoritesAdminController {

    private final MealFavoriteRepository mealFavoriteRepository;
    private final PostFavoriteRepository postFavoriteRepository;
    private final UserRepository userRepository;
    private final MealRepository mealRepository;
    private final PostRepository postRepository;

    public FavoritesAdminController(MealFavoriteRepository mealFavoriteRepository,
            PostFavoriteRepository postFavoriteRepository, UserRepository userRepository,
            MealRepository mealRepository, PostRepository postRepository) {
        this.mealFavoriteRepository = mealFavoriteRepository;
        this.postFavoriteRepository = postFavoriteRepository;
        this.userRepository = userRepository;
        this.mealRepository = mealRepository;
        this.postRepository = postRepository;
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
        Set<Integer> uniqueUsers = java.util.stream.Stream.concat(
                        foodFavorites.stream().map(favorite -> favorite.getUser().getUserId()),
                        postFavorites.stream().map(favorite -> favorite.getUser().getUserId()))
                .collect(Collectors.toSet());

        model.addAttribute("pageTitle", "Favorites");
        model.addAttribute("foodFavorites", foodFavorites);
        model.addAttribute("postFavorites", postFavorites);
        model.addAttribute("totalFoodFavorites", totalFood);
        model.addAttribute("totalPostFavorites", totalPost);
        model.addAttribute("usersWithFoodFavorites", uniqueFoodUsers.size());
        model.addAttribute("totalFavorites", totalFood + totalPost);
        model.addAttribute("usersWithFavorites", uniqueUsers.size());
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("meals", mealRepository.findAll());
        model.addAttribute("posts", postRepository.findAll());

        return "admin/favorite";
    }

    @PostMapping("/admin/favorites")
    @ResponseBody
    public ResponseEntity<?> createFavorite(@Valid @RequestBody AdminFavoriteRequest request) {
        return saveFavorite(null, request.kind(), request);
    }

    @PutMapping("/admin/favorites/{kind}/{favoriteId}")
    @ResponseBody
    public ResponseEntity<?> updateFavorite(@PathVariable String kind, @PathVariable Integer favoriteId,
            @Valid @RequestBody AdminFavoriteRequest request) {
        if (!kind.equals(request.kind())) {
            return ResponseEntity.badRequest().body(message("Favorite type cannot be changed while editing."));
        }
        return saveFavorite(favoriteId, kind, request);
    }

    private ResponseEntity<?> saveFavorite(Integer favoriteId, String kind, AdminFavoriteRequest request) {
        var user = userRepository.findById(request.userId()).orElse(null);
        if (user == null) return ResponseEntity.badRequest().body(message("Selected user was not found."));

        if ("meals".equals(kind)) {
            var meal = mealRepository.findById(request.contentId()).orElse(null);
            if (meal == null) return ResponseEntity.badRequest().body(message("Selected meal was not found."));
            MealFavorite favorite = favoriteId == null ? new MealFavorite() : mealFavoriteRepository.findById(favoriteId).orElse(null);
            if (favorite == null) return ResponseEntity.notFound().build();
            boolean duplicate = favoriteId == null
                    ? mealFavoriteRepository.existsByUserUserIdAndMealMealId(request.userId(), request.contentId())
                    : mealFavoriteRepository.existsByUserUserIdAndMealMealIdAndMealFavoriteIdNot(request.userId(), request.contentId(), favoriteId);
            if (duplicate) return ResponseEntity.badRequest().body(message("This meal is already in the user's favorites."));
            favorite.setUser(user);
            favorite.setMeal(meal);
            if (favorite.getSavedAt() == null) favorite.setSavedAt(LocalDateTime.now());
            MealFavorite saved = mealFavoriteRepository.save(favorite);
            return ResponseEntity.ok(Map.of(
                    "message", "Favorite saved successfully.",
                    "favoriteId", saved.getMealFavoriteId(),
                    "kind", "meals"));
        }
        if ("posts".equals(kind)) {
            var post = postRepository.findById(request.contentId()).orElse(null);
            if (post == null) return ResponseEntity.badRequest().body(message("Selected post was not found."));
            PostFavorite favorite = favoriteId == null ? new PostFavorite() : postFavoriteRepository.findById(favoriteId).orElse(null);
            if (favorite == null) return ResponseEntity.notFound().build();
            boolean duplicate = favoriteId == null
                    ? postFavoriteRepository.existsByUserUserIdAndPostPostId(request.userId(), request.contentId())
                    : postFavoriteRepository.existsByUserUserIdAndPostPostIdAndPostFavoriteIdNot(request.userId(), request.contentId(), favoriteId);
            if (duplicate) return ResponseEntity.badRequest().body(message("This post is already in the user's favorites."));
            favorite.setUser(user);
            favorite.setPost(post);
            if (favorite.getSavedAt() == null) favorite.setSavedAt(LocalDateTime.now());
            PostFavorite saved = postFavoriteRepository.save(favorite);
            return ResponseEntity.ok(Map.of(
                    "message", "Favorite saved successfully.",
                    "favoriteId", saved.getPostFavoriteId(),
                    "kind", "posts"));
        }
        return ResponseEntity.badRequest().body(message("Favorite type must be meals or posts."));
    }

    private Map<String, String> message(String value) {
        return Map.of("message", value);
    }

    @DeleteMapping("/admin/favorites/meals/{favoriteId}")
    @ResponseBody
    public ResponseEntity<Void> deleteMealFavorite(@PathVariable Integer favoriteId) {
        if (!mealFavoriteRepository.existsById(favoriteId)) {
            return ResponseEntity.notFound().build();
        }
        mealFavoriteRepository.deleteById(favoriteId);
        return ResponseEntity.noContent().build();
    }

    @DeleteMapping("/admin/favorites/posts/{favoriteId}")
    @ResponseBody
    public ResponseEntity<Void> deletePostFavorite(@PathVariable Integer favoriteId) {
        if (!postFavoriteRepository.existsById(favoriteId)) {
            return ResponseEntity.notFound().build();
        }
        postFavoriteRepository.deleteById(favoriteId);
        return ResponseEntity.noContent().build();
    }
}
