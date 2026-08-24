package com.nhamhealth.nhamhealth_api.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import com.nhamhealth.nhamhealth_api.entity.Share;

public interface ShareRepository extends JpaRepository<Share, Integer> {
    long countByReferenceTypeIgnoreCaseAndReferenceId(String referenceType, Integer referenceId);
}
