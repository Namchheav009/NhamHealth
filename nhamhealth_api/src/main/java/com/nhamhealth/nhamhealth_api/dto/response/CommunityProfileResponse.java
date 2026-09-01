package com.nhamhealth.nhamhealth_api.dto.response;

/** Public community identity and social counts; excludes private health details. */
public record CommunityProfileResponse(
        Integer id, String name, String avatarUrl, String role, String headline, String joinedLabel, boolean verified,
        long posts, long followers, long following, boolean followingAuthor) { }
