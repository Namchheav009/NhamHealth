package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.AiFoodAnalysis;

public interface AiFoodAnalysisRepository extends JpaRepository<AiFoodAnalysis, Integer> {

    List<AiFoodAnalysis> findAllByOrderByCreatedAtDesc();
}
