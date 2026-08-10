package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AdminMoodRequest(
        @NotBlank(message = "Mood name is required")
        @Size(max = 100, message = "Mood name must not exceed 100 characters")
        String moodName,
        @Size(max = 30, message = "Emoji must not exceed 30 characters")
        String emojiCode,
        Boolean active) {
}
