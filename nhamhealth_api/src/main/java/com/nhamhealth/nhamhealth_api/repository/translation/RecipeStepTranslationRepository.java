package com.nhamhealth.nhamhealth_api.repository.translation;
import java.util.*; import org.springframework.data.jpa.repository.JpaRepository; import com.nhamhealth.nhamhealth_api.entity.RecipeStepTranslation;
public interface RecipeStepTranslationRepository extends JpaRepository<RecipeStepTranslation,Integer>{ List<RecipeStepTranslation> findByRecipeStepStepIdInAndLanguageCode(Collection<Integer> ids,String lang); Optional<RecipeStepTranslation> findByRecipeStepStepIdAndLanguageCode(Integer id,String lang); }
