package com.nhamhealth.nhamhealth_api.repository.community;

import com.nhamhealth.nhamhealth_api.entity.*;
import java.util.*;
import org.springframework.data.domain.*;
import org.springframework.data.jpa.repository.*;

public interface ReportRepository
    extends JpaRepository<Report, Integer>, JpaSpecificationExecutor<Report> {
  boolean existsByReporterUserIdAndReportTypeAndTargetIdAndStatusIn(
      Integer userId, ReportType type, Integer targetId, Collection<ReportStatus> statuses);

  Page<Report> findByReporterUserIdOrderByCreatedAtDesc(Integer userId, Pageable pageable);

  long countByReportedUserUserId(Integer userId);
}
