package com.nhamhealth.nhamhealth_api.service.wellness;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.dao.DataIntegrityViolationException;

import com.nhamhealth.nhamhealth_api.dto.request.AdminMoodRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMoodDto;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.MoodTranslation;
import com.nhamhealth.nhamhealth_api.repository.translation.MoodTranslationRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.MoodRepository;

class MoodAdminServiceTests {

    private MoodRepository moodRepository;
    private MoodTranslationRepository moodTranslationRepository;
    private MoodAdminService service;

    @BeforeEach
    void setUp() {
        moodRepository = mock(MoodRepository.class);
        moodTranslationRepository = mock(MoodTranslationRepository.class);
        service = new MoodAdminService(moodRepository, moodTranslationRepository);
    }

    @Test
    void create_SavesMoodAndTranslations() {
        AdminMoodRequest request = new AdminMoodRequest("Happy", "សប្បាយរីករាយ", "1F604", true);

        when(moodRepository.findByMoodNameIgnoreCase("Happy")).thenReturn(Optional.empty());
        when(moodRepository.save(any(Mood.class))).thenAnswer(invocation -> {
            Mood mood = invocation.getArgument(0);
            mood.setMoodName("Happy");
            return mood;
        });

        MoodTranslation kmTrans = new MoodTranslation();
        kmTrans.setLanguageCode("km");
        kmTrans.setName("សប្បាយរីករាយ");
        when(moodTranslationRepository.findByMoodMoodIdAndLanguageCode(any(), org.mockito.ArgumentMatchers.eq("km")))
                .thenReturn(Optional.of(kmTrans));

        AdminMoodDto result = service.create(request);

        assertNotNull(result);
        assertEquals("Happy", result.moodName());
        assertEquals("សប្បាយរីករាយ", result.moodNameKm());
        assertEquals("1F604", result.emojiCode());
        assertTrue(result.active());

        ArgumentCaptor<MoodTranslation> captor = ArgumentCaptor.forClass(MoodTranslation.class);
        verify(moodTranslationRepository, times(2)).save(captor.capture());

        List<MoodTranslation> savedTranslations = captor.getAllValues();
        assertEquals("en", savedTranslations.get(0).getLanguageCode());
        assertEquals("Happy", savedTranslations.get(0).getName());
        assertEquals("km", savedTranslations.get(1).getLanguageCode());
        assertEquals("សប្បាយរីករាយ", savedTranslations.get(1).getName());
    }

    @Test
    void create_ThrowsWhenMoodNameExists() {
        AdminMoodRequest request = new AdminMoodRequest("Happy", "សប្បាយរីករាយ", "1F604", true);
        when(moodRepository.findByMoodNameIgnoreCase("Happy")).thenReturn(Optional.of(new Mood()));

        IllegalArgumentException ex = assertThrows(IllegalArgumentException.class, () -> service.create(request));
        assertEquals("A mood with this name already exists", ex.getMessage());
    }

    @Test
    void update_UpdatesTranslations() {
        Mood existing = new Mood();
        existing.setMoodId(1);
        existing.setMoodName("Sad");
        existing.setEmojiCode("1F622");
        existing.setIsActive(true);

        when(moodRepository.findById(1)).thenReturn(Optional.of(existing));
        when(moodRepository.findByMoodNameIgnoreCase("Sad Updated")).thenReturn(Optional.empty());
        when(moodRepository.save(any(Mood.class))).thenAnswer(i -> i.getArgument(0));

        MoodTranslation enTrans = new MoodTranslation();
        enTrans.setLanguageCode("en");
        enTrans.setName("Sad");
        when(moodTranslationRepository.findByMoodMoodIdAndLanguageCode(1, "en")).thenReturn(Optional.of(enTrans));

        MoodTranslation kmTrans = new MoodTranslation();
        kmTrans.setLanguageCode("km");
        kmTrans.setName("កើតទុក្ខ");
        when(moodTranslationRepository.findByMoodMoodIdAndLanguageCode(1, "km")).thenReturn(Optional.of(kmTrans));

        AdminMoodRequest request = new AdminMoodRequest("Sad Updated", "កើតទុក្ខកែប្រែ", "1F625", true);
        AdminMoodDto result = service.update(1, request);

        assertEquals("Sad Updated", result.moodName());
        assertEquals("Sad Updated", enTrans.getName());
        assertEquals("កើតទុក្ខកែប្រែ", kmTrans.getName());
        verify(moodTranslationRepository, times(2)).save(any(MoodTranslation.class));
    }

    @Test
    void update_RemovesKhmerTranslationWhenEmpty() {
        Mood existing = new Mood();
        existing.setMoodId(2);
        existing.setMoodName("Calm");

        when(moodRepository.findById(2)).thenReturn(Optional.of(existing));
        when(moodRepository.findByMoodNameIgnoreCase("Calm")).thenReturn(Optional.of(existing));
        when(moodRepository.save(any(Mood.class))).thenAnswer(i -> i.getArgument(0));

        MoodTranslation enTrans = new MoodTranslation();
        enTrans.setLanguageCode("en");
        enTrans.setName("Calm");
        when(moodTranslationRepository.findByMoodMoodIdAndLanguageCode(2, "en")).thenReturn(Optional.of(enTrans));

        MoodTranslation kmTrans = new MoodTranslation();
        kmTrans.setLanguageCode("km");
        kmTrans.setName("ស្ងប់ស្ងាត់");
        when(moodTranslationRepository.findByMoodMoodIdAndLanguageCode(2, "km")).thenReturn(Optional.of(kmTrans));

        AdminMoodRequest request = new AdminMoodRequest("Calm", "", "1F60C", true);
        AdminMoodDto result = service.update(2, request);

        assertEquals("Calm", result.moodName());
        verify(moodTranslationRepository).delete(kmTrans);
    }

    @Test
    void delete_RemovesTranslationsThenMood() {
        Mood mood = new Mood();
        when(moodRepository.findById(3)).thenReturn(Optional.of(mood));

        service.delete(3);

        verify(moodTranslationRepository).deleteByMoodMoodId(3);
        verify(moodRepository).delete(mood);
    }

    @Test
    void delete_ThrowsWhenIntegrityViolation() {
        Mood mood = new Mood();
        when(moodRepository.findById(3)).thenReturn(Optional.of(mood));
        doThrow(new DataIntegrityViolationException("FK violation")).when(moodRepository).flush();

        IllegalStateException ex = assertThrows(IllegalStateException.class, () -> service.delete(3));
        assertTrue(ex.getMessage().contains("used by wellness or AI records"));
    }
}
