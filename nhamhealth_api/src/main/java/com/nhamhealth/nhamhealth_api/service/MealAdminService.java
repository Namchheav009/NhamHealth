package com.nhamhealth.nhamhealth_api.service;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;

import com.nhamhealth.nhamhealth_api.dto.response.MealAdminRowDto;
import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.Review;
import com.nhamhealth.nhamhealth_api.repository.MealFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.MealTagRepository;
import com.nhamhealth.nhamhealth_api.repository.ReviewRepository;

@Service
public class MealAdminService {

    private final MealRepository mealRepository;
    private final MealTagRepository mealTagRepository;
    private final MealFavoriteRepository mealFavoriteRepository;
    private final ReviewRepository reviewRepository;

    public MealAdminService(
            MealRepository mealRepository,
            MealTagRepository mealTagRepository,
            MealFavoriteRepository mealFavoriteRepository,
            ReviewRepository reviewRepository) {
        this.mealRepository = mealRepository;
        this.mealTagRepository = mealTagRepository;
        this.mealFavoriteRepository = mealFavoriteRepository;
        this.reviewRepository = reviewRepository;
    }

    public List<MealAdminRowDto> getMealsForAdmin() {
        return mealRepository.findAllByOrderByUpdatedAtDesc().stream()
                .map(this::toAdminRow)
                .collect(Collectors.toList());
    }

    private MealAdminRowDto toAdminRow(Meal meal) {
        String category = meal.getCategory() != null ? meal.getCategory().getCategoryName() : "Uncategorized";
        String status = Boolean.TRUE.equals(meal.getIsPublished()) ? "Published" : "Draft";
        String calories = meal.getCaloriesCached() == null ? "—"
                : meal.getCaloriesCached().setScale(0, java.math.RoundingMode.HALF_UP).toPlainString() + " kcal";
        String servingSize = meal.getServings() == null ? "—" : meal.getServings() + " serving";
        String updatedDate = meal.getUpdatedAt() == null ? "—"
                : meal.getUpdatedAt().format(java.time.format.DateTimeFormatter.ofPattern("MMM dd, yyyy"));

        List<String> tags = mealTagRepository.findByMealMealId(meal.getMealId()).stream()
                .map(tag -> tag.getTag() != null ? tag.getTag().getTagName() : null)
                .filter(tag -> tag != null && !tag.isBlank())
                .collect(Collectors.toList());

        List<Review> reviews = reviewRepository.findByMealMealId(meal.getMealId());
        double averageRating = reviews.stream()
                .filter(review -> review.getRating() != null)
                .mapToDouble(Review::getRating)
                .average()
                .orElse(0.0);
        String reviewsText = reviews.isEmpty() ? "0 (0)" : String.format("%.1f (%d)", averageRating, reviews.size());

        long favorites = mealFavoriteRepository.countByMealMealId(meal.getMealId());

        return new MealAdminRowDto(
                meal.getMealId(),
                mealIconClass(category),
                meal.getMealName(),
                category,
                calories,
                servingSize,
                tags,
                reviewsText,
                Math.toIntExact(favorites),
                status,
                updatedDate);
    }

    private String mealIconClass(String category) {
        String normalized = category == null ? "" : category.toLowerCase();
        if (normalized.contains("soup") || normalized.contains("bowl")) {
            return "fa-bowl-food";
        }
        if (normalized.contains("salad")) {
            return "fa-leaf";
        }
        if (normalized.contains("breakfast")) {
            return "fa-egg";
        }
        if (normalized.contains("fish") || normalized.contains("salmon")) {
            return "fa-fish";
        }
        if (normalized.contains("stir") || normalized.contains("rice")) {
            return "fa-bowl-rice";
        }
        return "fa-utensils";
    }
}
