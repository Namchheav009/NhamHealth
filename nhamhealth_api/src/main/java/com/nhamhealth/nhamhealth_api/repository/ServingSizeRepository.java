package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.ServingSize;

public interface ServingSizeRepository extends JpaRepository<ServingSize, Integer> {
    List<ServingSize> findAllByOrderByServingSizeNameAsc();
}
