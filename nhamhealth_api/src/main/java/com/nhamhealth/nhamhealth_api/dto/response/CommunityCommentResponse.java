package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;

public record CommunityCommentResponse(
        Integer id, String author, String authorAvatarUrl, String text, LocalDateTime createdAt,
        Integer parentCommentId, long likes, boolean liked) { }
