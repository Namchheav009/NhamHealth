package com.nhamhealth.nhamhealth_api.repository.translation;
import java.util.*; import org.springframework.data.jpa.repository.JpaRepository; import com.nhamhealth.nhamhealth_api.entity.MealCategoryTranslation;
public interface MealCategoryTranslationRepository extends JpaRepository<MealCategoryTranslation, Integer> {
    Optional<MealCategoryTranslation> findByCategoryCategoryIdAndLanguageCode(Integer id, String lang);
    List<MealCategoryTranslation> findByLanguageCode(String lang);
    List<MealCategoryTranslation> findByCategoryCategoryId(Integer categoryId);
    void deleteByCategoryCategoryId(Integer categoryId);
}
