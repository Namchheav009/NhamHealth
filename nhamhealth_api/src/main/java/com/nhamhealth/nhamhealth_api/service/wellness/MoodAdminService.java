package com.nhamhealth.nhamhealth_api.service.wellness;

import java.util.Objects;
import java.util.Optional;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.request.AdminMoodRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMoodDto;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.MoodTranslation;
import com.nhamhealth.nhamhealth_api.repository.translation.MoodTranslationRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.MoodRepository;

@Service
public class MoodAdminService {

    private final MoodRepository moodRepository;
    private final MoodTranslationRepository moodTranslationRepository;

    public MoodAdminService(
            MoodRepository moodRepository,
            MoodTranslationRepository moodTranslationRepository) {
        this.moodRepository = moodRepository;
        this.moodTranslationRepository = moodTranslationRepository;
    }

    @Transactional
    @CacheEvict(value = "moods", allEntries = true)
    public AdminMoodDto create(AdminMoodRequest request) {
        String name = request.moodName().trim();
        if (moodRepository.findByMoodNameIgnoreCase(name).isPresent()) {
            throw new IllegalArgumentException("A mood with this name already exists");
        }

        Mood mood = new Mood();
        apply(mood, request);
        Mood saved = moodRepository.save(mood);

        MoodTranslation en = new MoodTranslation();
        en.setMood(saved);
        en.setLanguageCode("en");
        en.setName(saved.getMoodName());
        moodTranslationRepository.save(en);

        if (request.moodNameKm() != null && !request.moodNameKm().isBlank()) {
            MoodTranslation km = new MoodTranslation();
            km.setMood(saved);
            km.setLanguageCode("km");
            km.setName(request.moodNameKm().trim());
            moodTranslationRepository.save(km);
        }

        return toDto(saved);
    }

    @Transactional
    @CacheEvict(value = "moods", allEntries = true)
    public AdminMoodDto update(Integer moodId, AdminMoodRequest request) {
        Mood mood = moodRepository.findById(moodId)
                .orElseThrow(() -> new IllegalArgumentException("Mood not found"));

        String name = request.moodName().trim();
        moodRepository.findByMoodNameIgnoreCase(name)
                .filter(existing -> !Objects.equals(existing.getMoodId(), moodId))
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("A mood with this name already exists");
                });

        apply(mood, request);
        Mood saved = moodRepository.save(mood);

        MoodTranslation en = moodTranslationRepository
                .findByMoodMoodIdAndLanguageCode(moodId, "en")
                .orElseGet(() -> {
                    MoodTranslation t = new MoodTranslation();
                    t.setMood(saved);
                    t.setLanguageCode("en");
                    return t;
                });
        en.setName(saved.getMoodName());
        moodTranslationRepository.save(en);

        Optional<MoodTranslation> kmOpt = moodTranslationRepository.findByMoodMoodIdAndLanguageCode(moodId, "km");
        if (request.moodNameKm() != null && !request.moodNameKm().isBlank()) {
            MoodTranslation km = kmOpt.orElseGet(() -> {
                MoodTranslation t = new MoodTranslation();
                t.setMood(saved);
                t.setLanguageCode("km");
                return t;
            });
            km.setName(request.moodNameKm().trim());
            moodTranslationRepository.save(km);
        } else {
            kmOpt.ifPresent(moodTranslationRepository::delete);
        }

        return toDto(saved);
    }

    @Transactional
    @CacheEvict(value = "moods", allEntries = true)
    public void delete(Integer moodId) {
        Mood mood = moodRepository.findById(moodId)
                .orElseThrow(() -> new IllegalArgumentException("Mood not found"));
        try {
            moodTranslationRepository.deleteByMoodMoodId(moodId);
            moodRepository.delete(mood);
            moodRepository.flush();
        } catch (DataIntegrityViolationException ex) {
            throw new IllegalStateException("This mood is used by wellness or AI records. Mark it inactive instead.", ex);
        }
    }

    private void apply(Mood mood, AdminMoodRequest request) {
        mood.setMoodName(request.moodName().trim());
        mood.setEmojiCode(request.emojiCode() == null || request.emojiCode().isBlank()
                ? null : request.emojiCode().trim());
        mood.setIsActive(request.active() == null || request.active());
    }

    public AdminMoodDto toDto(Mood mood) {
        String kmName = moodTranslationRepository
                .findByMoodMoodIdAndLanguageCode(mood.getMoodId(), "km")
                .map(MoodTranslation::getName)
                .orElse(null);

        return new AdminMoodDto(
                mood.getMoodId(),
                mood.getMoodName(),
                kmName,
                mood.getEmojiCode() == null ? "" : mood.getEmojiCode(),
                Boolean.TRUE.equals(mood.getIsActive()));
    }
}
