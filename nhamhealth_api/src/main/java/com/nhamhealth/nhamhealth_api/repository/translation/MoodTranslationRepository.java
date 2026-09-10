package com.nhamhealth.nhamhealth_api.repository.translation;
import java.util.*; import org.springframework.data.jpa.repository.JpaRepository; import com.nhamhealth.nhamhealth_api.entity.MoodTranslation;
public interface MoodTranslationRepository extends JpaRepository<MoodTranslation,Integer>{ List<MoodTranslation> findByMoodMoodIdInAndLanguageCode(Collection<Integer> ids,String lang); }
