package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.Mood;

/** A mood that is available for selection in the mobile application. */
public record MoodResponse(Integer id, String moodName, String emojiCode) {
    public static MoodResponse from(Mood mood) {
        return new MoodResponse(
                mood.getMoodId(),
                mood.getMoodName(),
                mood.getEmojiCode() == null ? "" : mood.getEmojiCode());
    }
}
