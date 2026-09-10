package com.nhamhealth.nhamhealth_api.repository.community;

import com.nhamhealth.nhamhealth_api.entity.ModerationAction;
import com.nhamhealth.nhamhealth_api.entity.ModerationActionType;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface ModerationActionRepository extends JpaRepository<ModerationAction, Integer> {
  List<ModerationAction> findByTargetUserUserIdOrderByCreatedAtDesc(Integer userId);

  Page<ModerationAction> findAllByOrderByCreatedAtDesc(Pageable pageable);

  @Query("""
      select a from ModerationAction a
      where a.targetUser.userId = :userId
        and a.actionType = :type
        and a.reversedAt is null
        and (a.expiresAt is null or a.expiresAt > :now)
      order by a.expiresAt desc nulls first, a.createdAt desc
      """)
  List<ModerationAction> findActiveRestrictions(
      @Param("userId") Integer userId,
      @Param("type") ModerationActionType type,
      @Param("now") LocalDateTime now);
}
