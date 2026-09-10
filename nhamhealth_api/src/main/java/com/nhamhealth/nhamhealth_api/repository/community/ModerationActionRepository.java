package com.nhamhealth.nhamhealth_api.repository.community;

import com.nhamhealth.nhamhealth_api.entity.ModerationAction;
import java.util.List;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ModerationActionRepository extends JpaRepository<ModerationAction, Integer> {
  List<ModerationAction> findByTargetUserUserIdOrderByCreatedAtDesc(Integer userId);

  Page<ModerationAction> findAllByOrderByCreatedAtDesc(Pageable pageable);
}
