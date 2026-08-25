package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;
import java.util.List;

public record CommunitySharedPostResponse(
        Integer id,
        Integer authorId,
        String author,
        String role,
        String authorAvatarUrl,
        String description,
        String imageUrl,
        List<String> imageUrls,
        LocalDateTime createdAt) { }
