package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiFoodSuggestion;

public interface AiFoodSuggestionRepository extends JpaRepository<AiFoodSuggestion, Integer> {

    List<AiFoodSuggestion> findAllByOrderByPriorityDesc();
}
