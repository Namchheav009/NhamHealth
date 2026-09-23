package com.nhamhealth.nhamhealth_api.repository.translation;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.nhamhealth.nhamhealth_api.entity.TranslationMemory;

@Repository
public interface TranslationMemoryRepository extends JpaRepository<TranslationMemory, Integer> {

    Optional<TranslationMemory> findBySourceHashAndLanguageCode(String sourceHash, String languageCode);
}

