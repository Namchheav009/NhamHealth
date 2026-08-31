package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;
import java.math.BigDecimal;
import java.util.List;

public record CommunityPostResponse(
        Integer id, String description, String imageUrl, List<String> imageUrls,
        Integer authorId, String author, String role, String authorAvatarUrl, List<String> tags,
        LocalDateTime createdAt, long likes, long comments,
        boolean liked, boolean followingAuthor, String visibility,
        boolean allowComments, boolean allowReplies, List<Integer> tagIds,
        String mealName, Integer cookingTimeMinutes, Integer servings, String difficulty,
        Integer categoryId, String categoryName, String aiStatus, String aiReviewReason, Integer mealId, boolean saved,
        List<MealPostIngredient> ingredients, List<MealPostStep> steps) {
    public record MealPostIngredient(String ingredientName, BigDecimal amount, String unit) { }
    public record MealPostStep(Integer stepNumber, String instruction, String imageUrl) { }
}
