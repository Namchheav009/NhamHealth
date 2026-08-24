package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;
import java.util.List;

public record CommunityPostResponse(
        Integer id, String title, String description, String imageUrl,
        String author, String role, String authorAvatarUrl, List<String> tags,
        LocalDateTime createdAt, long likes, long comments, long shares,
        boolean liked, boolean followingAuthor) { }
