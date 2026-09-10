package com.nhamhealth.nhamhealth_api.repository.community;

import com.nhamhealth.nhamhealth_api.entity.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ModerationAppealRepository extends JpaRepository<ModerationAppeal, Integer> {
  boolean existsByModerationActionActionIdAndUserUserId(Integer actionId, Integer userId);

  Page<ModerationAppeal> findByStatusOrderByCreatedAtAsc(AppealStatus status, Pageable pageable);
}
