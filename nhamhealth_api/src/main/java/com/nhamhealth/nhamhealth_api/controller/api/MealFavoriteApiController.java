package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.NOT_FOUND;
import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Objects;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.FavoriteMealResponse;
import com.nhamhealth.nhamhealth_api.dto.request.BulkMealFavoritesRequest;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealFavorite;
import com.nhamhealth.nhamhealth_api.repository.meal.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

@RestController
@RequestMapping("/api/v1/favorites/meals")
public class MealFavoriteApiController {

    private final MealFavoriteRepository favoriteRepository;
    private final MealRepository mealRepository;
    private final UserRepository userRepository;

    public MealFavoriteApiController(MealFavoriteRepository favoriteRepository,
            MealRepository mealRepository, UserRepository userRepository) {
        this.favoriteRepository = favoriteRepository;
        this.mealRepository = mealRepository;
        this.userRepository = userRepository;
    }

    @GetMapping
    @Transactional(readOnly = true)
    public List<FavoriteMealResponse> list(@AuthenticationPrincipal Jwt jwt) {
        List<MealFavorite> favorites = favoriteRepository
                .findAllByUserUserIdOrderBySavedAtDesc(userId(jwt));
        if (favorites.isEmpty()) return List.of();

        return favorites.stream()
                .map(this::toResponse)
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

        @PostMapping("/bulk")
        @Transactional
        public ResponseEntity<Void> addAll(
                        @AuthenticationPrincipal Jwt jwt,
                        @RequestBody BulkMealFavoritesRequest request) {
                List<Integer> mealIds = request == null || request.mealIds() == null
                                ? List.of()
                                : request.mealIds().stream().filter(Objects::nonNull).distinct().limit(100).toList();
                if (!mealIds.isEmpty()) {
                        favoriteRepository.addAllPublishedByUserId(userId(jwt), mealIds);
                }
                return ResponseEntity.noContent().build();
        }

        @DeleteMapping
        @Transactional
        public ResponseEntity<Void> removeAll(@AuthenticationPrincipal Jwt jwt) {
                favoriteRepository.deleteAllByUserId(userId(jwt));
                return ResponseEntity.noContent().build();
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
        return toResponse(favorite, 0);
    }

    private FavoriteMealResponse toResponse(MealFavorite favorite, double rating) {
        Meal meal = favorite.getMeal();
        return new FavoriteMealResponse(meal.getMealId(), meal.getMealName(), meal.getMainImageUrl(),
                meal.getCaloriesCached() == null ? BigDecimal.ZERO : meal.getCaloriesCached(), rating,
                meal.getCategory().getCategoryName(), favorite.getSavedAt());
    }
}
