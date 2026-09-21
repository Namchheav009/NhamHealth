package com.nhamhealth.nhamhealth_api.dto.response;

import java.util.List;

public record AssistantChatResponse(String reply, List<String> actions) {
    public AssistantChatResponse {
        actions = actions == null ? List.of() : List.copyOf(actions);
    }
}
