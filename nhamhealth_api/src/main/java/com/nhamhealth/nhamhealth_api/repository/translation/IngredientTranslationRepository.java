package com.nhamhealth.nhamhealth_api.repository.translation;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.IngredientTranslation;

public interface IngredientTranslationRepository extends JpaRepository<IngredientTranslation, Integer> {
    List<IngredientTranslation> findByIngredientIngredientIdInAndLanguageCode(
            Collection<Integer> ids, String lang);

    Optional<IngredientTranslation> findByIngredientIngredientIdAndLanguageCode(
            Integer id, String lang);

    List<IngredientTranslation> findByLanguageCode(String languageCode);

    List<IngredientTranslation> findTop20ByLanguageCodeAndNameContainingIgnoreCaseOrderByNameAsc(
            String languageCode, String name);
}
