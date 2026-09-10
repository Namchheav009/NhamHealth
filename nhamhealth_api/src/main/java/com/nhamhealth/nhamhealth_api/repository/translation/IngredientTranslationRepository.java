package com.nhamhealth.nhamhealth_api.repository.translation;
import java.util.*; import org.springframework.data.jpa.repository.JpaRepository; import com.nhamhealth.nhamhealth_api.entity.IngredientTranslation;
public interface IngredientTranslationRepository extends JpaRepository<IngredientTranslation,Integer>{ List<IngredientTranslation> findByIngredientIngredientIdInAndLanguageCode(Collection<Integer> ids,String lang); Optional<IngredientTranslation> findByIngredientIngredientIdAndLanguageCode(Integer id,String lang); }
