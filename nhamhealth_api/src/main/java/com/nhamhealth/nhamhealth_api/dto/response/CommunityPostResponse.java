package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.LocalDateTime;
import java.util.List;

public record CommunityPostResponse(
        Integer id, String description, String imageUrl, List<String> imageUrls,
        Integer authorId, String author, String role, String authorAvatarUrl, List<String> tags,
        LocalDateTime createdAt, long likes, long comments, long shares,
        boolean liked, boolean followingAuthor, String visibility,
<<<<<<< HEAD
        boolean allowComments, boolean allowReplies, List<Integer> tagIds,
        CommunitySharedPostResponse sharedPost) { }
=======
        boolean allowComments, boolean allowReplies, List<Integer> tagIds) { }
>>>>>>> de26f8c42978dce467e11832233dcabe163d6bc0
