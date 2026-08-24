package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

public record CommunityPersonResponse(
        Integer id, String name, String avatarUrl, String detail,
        List<String> tags, long mutualFriends, String connectionStatus) { }
