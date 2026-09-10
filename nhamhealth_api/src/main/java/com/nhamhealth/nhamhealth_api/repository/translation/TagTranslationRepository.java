package com.nhamhealth.nhamhealth_api.repository.translation;
import java.util.*; import org.springframework.data.jpa.repository.JpaRepository; import com.nhamhealth.nhamhealth_api.entity.TagTranslation;
public interface TagTranslationRepository extends JpaRepository<TagTranslation,Integer>{ List<TagTranslation> findByTagTagIdInAndLanguageCode(Collection<Integer> ids,String lang); }
