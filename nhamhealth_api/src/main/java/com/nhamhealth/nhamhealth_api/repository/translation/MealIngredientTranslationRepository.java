package com.nhamhealth.nhamhealth_api.repository.translation;
import java.util.*; import org.springframework.data.jpa.repository.JpaRepository; import com.nhamhealth.nhamhealth_api.entity.MealIngredientTranslation;
public interface MealIngredientTranslationRepository extends JpaRepository<MealIngredientTranslation,Integer>{ List<MealIngredientTranslation> findByMealIngredientMealIngredientIdInAndLanguageCode(Collection<Integer> ids,String lang); Optional<MealIngredientTranslation> findByMealIngredientMealIngredientIdAndLanguageCode(Integer id,String lang); }
