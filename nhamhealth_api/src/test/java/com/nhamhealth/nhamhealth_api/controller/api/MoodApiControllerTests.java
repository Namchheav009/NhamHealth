package com.nhamhealth.nhamhealth_api.controller.api;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.nhamhealth.nhamhealth_api.dto.response.MoodResponse;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.MoodTranslation;
import com.nhamhealth.nhamhealth_api.repository.translation.MoodTranslationRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.MoodRepository;

class MoodApiControllerTests {

    private MoodRepository moodRepository;
    private MoodTranslationRepository moodTranslationRepository;
    private MoodApiController controller;

    @BeforeEach
    void setUp() {
        moodRepository = mock(MoodRepository.class);
        moodTranslationRepository = mock(MoodTranslationRepository.class);
        controller = new MoodApiController(moodRepository, moodTranslationRepository);
    }

    @Test
    void activeMoods_ReturnsEnglishByDefault() {
        Mood mood = new Mood();
        mood.setMoodName("Happy");
        mood.setEmojiCode("1F604");

        MoodTranslation km = new MoodTranslation();
        km.setMood(mood);
        km.setLanguageCode("km");
        km.setName("សប្បាយរីករាយ");

        when(moodRepository.findAllByIsActiveTrueOrderByMoodNameAsc()).thenReturn(List.of(mood));
        when(moodTranslationRepository.findByLanguageCode("km")).thenReturn(List.of(km));

        ResponseEntity<List<MoodResponse>> response = controller.activeMoods("en", null);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().size());

        MoodResponse item = response.getBody().get(0);
        assertEquals("Happy", item.moodName());
        assertEquals("សប្បាយរីករាយ", item.moodNameKm());
        assertEquals("1F604", item.emojiCode());
    }

    @Test
    void activeMoods_ReturnsKhmerWhenRequested() {
        Mood mood = new Mood();
        mood.setMoodName("Happy");
        mood.setEmojiCode("1F604");

        MoodTranslation km = new MoodTranslation();
        km.setMood(mood);
        km.setLanguageCode("km");
        km.setName("សប្បាយរីករាយ");

        when(moodRepository.findAllByIsActiveTrueOrderByMoodNameAsc()).thenReturn(List.of(mood));
        when(moodTranslationRepository.findByLanguageCode("km")).thenReturn(List.of(km));

        ResponseEntity<List<MoodResponse>> response = controller.activeMoods("km", null);

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals(1, response.getBody().size());

        MoodResponse item = response.getBody().get(0);
        assertEquals("សប្បាយរីករាយ", item.moodName());
        assertEquals("សប្បាយរីករាយ", item.moodNameKm());
    }

    @Test
    void activeMoods_ResolvesAcceptLanguageHeader() {
        Mood mood = new Mood();
        mood.setMoodName("Calm");
        mood.setEmojiCode("1F60C");

        MoodTranslation km = new MoodTranslation();
        km.setMood(mood);
        km.setLanguageCode("km");
        km.setName("ស្ងប់ស្ងាត់");

        when(moodRepository.findAllByIsActiveTrueOrderByMoodNameAsc()).thenReturn(List.of(mood));
        when(moodTranslationRepository.findByLanguageCode("km")).thenReturn(List.of(km));

        ResponseEntity<List<MoodResponse>> response = controller.activeMoods(null, "km-KH,km;q=0.9");

        assertEquals(HttpStatus.OK, response.getStatusCode());
        assertNotNull(response.getBody());
        assertEquals("ស្ងប់ស្ងាត់", response.getBody().get(0).moodName());
    }
}

