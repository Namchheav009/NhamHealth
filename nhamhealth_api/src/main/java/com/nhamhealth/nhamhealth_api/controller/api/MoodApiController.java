package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.MoodResponse;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.MoodTranslation;
import com.nhamhealth.nhamhealth_api.repository.translation.MoodTranslationRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.MoodRepository;

@RestController
@RequestMapping("/api/v1/moods")
public class MoodApiController {

    private final MoodRepository moodRepository;
    private final MoodTranslationRepository moodTranslationRepository;

    public MoodApiController(
            MoodRepository moodRepository,
            MoodTranslationRepository moodTranslationRepository) {
        this.moodRepository = moodRepository;
        this.moodTranslationRepository = moodTranslationRepository;
    }

    /**
     * Deliberately returns only active entries, localized by lang or Accept-Language header.
     */
    @GetMapping
    public ResponseEntity<List<MoodResponse>> activeMoods(
            @RequestParam(required = false) String lang,
            @RequestHeader(value = "Accept-Language", required = false) String acceptLanguage) {
        String normalizedLang = resolveLanguage(lang, acceptLanguage);
        List<Mood> moods = moodRepository.findAllByIsActiveTrueOrderByMoodNameAsc();

        Map<Integer, MoodTranslation> kmTranslations = moodTranslationRepository
                .findByLanguageCode("km")
                .stream()
                .collect(Collectors.toMap(t -> t.getMood().getMoodId(), Function.identity(), (a, b) -> a));

        List<MoodResponse> response = moods.stream().map(mood -> {
            MoodTranslation km = kmTranslations.get(mood.getMoodId());
            String kmName = km != null && km.getName() != null && !km.getName().isBlank()
                    ? km.getName().trim() : null;
            String displayName = "km".equals(normalizedLang) && kmName != null
                    ? kmName : mood.getMoodName();
            return new MoodResponse(
                    mood.getMoodId(),
                    displayName,
                    kmName,
                    mood.getEmojiCode() == null ? "" : mood.getEmojiCode());
        }).toList();

        return ResponseEntity.ok(response);
    }

    private String resolveLanguage(String lang, String acceptLanguage) {
        if (lang != null && !lang.isBlank()) {
            return "km".equalsIgnoreCase(lang.trim()) ? "km" : "en";
        }
        if (acceptLanguage != null && acceptLanguage.toLowerCase().startsWith("km")) {
            return "km";
        }
        return "en";
    }
}
