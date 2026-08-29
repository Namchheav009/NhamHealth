package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record RecipeResponse(
        Integer id, String authorName, String recipeName, String description, String mainImageUrl,
        Integer cookingTimeMinutes, Integer servings, String difficulty, String status,
        String aiStatus, String aiReviewReason,
        LocalDateTime publishedAt, LocalDateTime createdAt, LocalDateTime updatedAt,
        List<String> tags, List<RecipeIngredient> ingredients, List<RecipeStep> steps,
        RecipeReview latestReview, Integer postId, Integer mealId, boolean saved) {
    public record RecipeIngredient(String name, BigDecimal amount, String unit, String preparationNote) { }
    public record RecipeStep(Integer number, String title, String instruction, String imageUrl) { }
    public record RecipeReview(String status, String summary, String feedback, String modelName, LocalDateTime createdAt) { }
}
