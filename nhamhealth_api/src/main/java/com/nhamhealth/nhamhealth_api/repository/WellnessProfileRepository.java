package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;

public interface WellnessProfileRepository extends JpaRepository<WellnessProfile, Integer> {
}
