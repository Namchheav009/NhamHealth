package com.nhamhealth.nhamhealth_api.repository.wellness;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;

import java.util.Optional;

public interface WellnessProfileRepository extends JpaRepository<WellnessProfile, Integer> {

    Optional<WellnessProfile> findByUser_UserId(Integer userId);
}
