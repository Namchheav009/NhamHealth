package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.OffsetDateTime;

public record CommunityCommentResponse(
        Integer id, String author, String authorAvatarUrl, String text, OffsetDateTime createdAt,
        Integer parentCommentId, long likes, boolean liked, boolean canDelete) { }
