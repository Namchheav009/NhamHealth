package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.NOT_FOUND;
import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.FavoriteMealResponse;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealFavorite;
import com.nhamhealth.nhamhealth_api.repository.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.ReviewRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@RestController
@RequestMapping("/api/v1/favorites/meals")
public class MealFavoriteApiController {

    private final MealFavoriteRepository favoriteRepository;
    private final MealRepository mealRepository;
    private final UserRepository userRepository;
    private final ReviewRepository reviewRepository;

    public MealFavoriteApiController(MealFavoriteRepository favoriteRepository,
            MealRepository mealRepository, UserRepository userRepository,
            ReviewRepository reviewRepository) {
        this.favoriteRepository = favoriteRepository;
        this.mealRepository = mealRepository;
        this.userRepository = userRepository;
        this.reviewRepository = reviewRepository;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<FavoriteMealResponse> list(@AuthenticationPrincipal Jwt jwt) {
        List<MealFavorite> favorites = favoriteRepository
                .findAllByUserUserIdOrderBySavedAtDesc(userId(jwt));
        if (favorites.isEmpty()) return List.of();

        List<Integer> mealIds = favorites.stream()
                .map(favorite -> favorite.getMeal().getMealId())
                .toList();
        Map<Integer, Double> ratings = reviewRepository
                .findAverageRatingsByMealIds(mealIds)
                .stream()
                .collect(Collectors.toMap(
                        row -> ((Number) row[0]).intValue(),
                        row -> ((Number) row[1]).doubleValue()));

        return favorites.stream()
                .map(favorite -> toResponse(
                        favorite,
                        ratings.getOrDefault(favorite.getMeal().getMealId(), 0.0)))
                .toList();
    }

    @PostMapping("/{mealId}")
    @Transactional
    public ResponseEntity<FavoriteMealResponse> add(@AuthenticationPrincipal Jwt jwt,
            @PathVariable Integer mealId) {
        Integer userId = userId(jwt);
        MealFavorite favorite = favoriteRepository
                .findByUserUserIdAndMealMealId(userId, mealId)
                .orElseGet(() -> {
                    Meal meal = mealRepository.findById(mealId)
                            .filter(value -> Boolean.TRUE.equals(value.getIsPublished()))
                            .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Meal not found."));
                    MealFavorite value = new MealFavorite();
                    value.setUser(userRepository.getReferenceById(userId));
                    value.setMeal(meal);
                    value.setSavedAt(LocalDateTime.now());
                    return favoriteRepository.save(value);
                });
        return ResponseEntity.ok(toResponse(favorite));
    }

    @DeleteMapping("/{mealId}")
    @Transactional
    public ResponseEntity<Void> remove(@AuthenticationPrincipal Jwt jwt,
            @PathVariable Integer mealId) {
        return favoriteRepository.findByUserUserIdAndMealMealId(userId(jwt), mealId)
                .map(value -> {
                    favoriteRepository.delete(value);
                    return ResponseEntity.noContent().<Void>build();
                }).orElseGet(() -> ResponseEntity.noContent().build());
    }

    private Integer userId(Jwt jwt) {
        if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required.");
        Number value = jwt.getClaim("userId");
        if (value == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID.");
        return value.intValue();
    }

    private FavoriteMealResponse toResponse(MealFavorite favorite) {
        Meal meal = favorite.getMeal();
        double rating = reviewRepository.findByMealMealId(meal.getMealId()).stream()
                .mapToInt(review -> review.getRating() == null ? 0 : review.getRating())
                .average().orElse(0);
        return toResponse(favorite, rating);
    }

    private FavoriteMealResponse toResponse(MealFavorite favorite, double rating) {
        Meal meal = favorite.getMeal();
        return new FavoriteMealResponse(meal.getMealId(), meal.getMealName(), meal.getMainImageUrl(),
                meal.getCaloriesCached() == null ? BigDecimal.ZERO : meal.getCaloriesCached(), rating,
                meal.getCategory().getCategoryName(), favorite.getSavedAt());
    }
}
