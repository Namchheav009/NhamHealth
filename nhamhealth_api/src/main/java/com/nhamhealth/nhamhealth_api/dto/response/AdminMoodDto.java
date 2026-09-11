package com.nhamhealth.nhamhealth_api.dto.response;

public record AdminMoodDto(
        Integer id,
        String moodName,
        String moodNameKm,
        String emojiCode,
        boolean active) {
}

