package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;
import java.util.List;

public record CommunityPostResponse(
        Integer id, String description, String imageUrl, List<String> imageUrls,
        Integer authorId, String author, String role, String authorAvatarUrl, List<String> tags,
        LocalDateTime createdAt, long likes, long comments,
        boolean liked, boolean followingAuthor, String visibility,
        boolean allowComments, boolean allowReplies, List<Integer> tagIds,
        String mealName, Integer cookingTimeMinutes, Integer servings, String difficulty,
        String aiStatus, String aiReviewReason, Integer mealId) { }
