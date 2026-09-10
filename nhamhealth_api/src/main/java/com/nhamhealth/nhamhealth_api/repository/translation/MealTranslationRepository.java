package com.nhamhealth.nhamhealth_api.repository.translation;
import java.util.*; import org.springframework.data.jpa.repository.JpaRepository; import com.nhamhealth.nhamhealth_api.entity.MealTranslation;
public interface MealTranslationRepository extends JpaRepository<MealTranslation,Integer>{ Optional<MealTranslation> findByMealMealIdAndLanguageCode(Integer id,String lang); }
