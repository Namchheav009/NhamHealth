package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.Mood;

/** A mood that is available for selection in the mobile application. */
public record MoodResponse(Integer id, String moodName, String moodNameKm, String emojiCode) {

    public MoodResponse(Integer id, String moodName, String emojiCode) {
        this(id, moodName, null, emojiCode);
    }

    public static MoodResponse from(Mood mood) {
        return new MoodResponse(
                mood.getMoodId(),
                mood.getMoodName(),
                null,
                mood.getEmojiCode() == null ? "" : mood.getEmojiCode());
    }

    public static MoodResponse from(Mood mood, String moodNameKm) {
        return new MoodResponse(
                mood.getMoodId(),
                mood.getMoodName(),
                moodNameKm,
                mood.getEmojiCode() == null ? "" : mood.getEmojiCode());
    }
}
