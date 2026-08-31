package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.Size;

public record CommunityShareRequest(
        @Size(max = 255) String message,
        @Size(max = 20) String visibility) {
}
