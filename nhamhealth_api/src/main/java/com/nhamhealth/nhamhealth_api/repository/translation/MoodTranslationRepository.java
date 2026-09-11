package com.nhamhealth.nhamhealth_api.repository.translation;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.MoodTranslation;

public interface MoodTranslationRepository extends JpaRepository<MoodTranslation, Integer> {
    List<MoodTranslation> findByMoodMoodIdInAndLanguageCode(Collection<Integer> ids, String lang);
    Optional<MoodTranslation> findByMoodMoodIdAndLanguageCode(Integer moodId, String lang);
    List<MoodTranslation> findByLanguageCode(String lang);
    List<MoodTranslation> findByMoodMoodId(Integer moodId);
    void deleteByMoodMoodId(Integer moodId);
}
