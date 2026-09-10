package com.nhamhealth.nhamhealth_api.repository.community;

import com.nhamhealth.nhamhealth_api.entity.ReportAttachment;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReportAttachmentRepository extends JpaRepository<ReportAttachment, Integer> {
  List<ReportAttachment> findByReportReportIdOrderByDisplayOrder(Integer reportId);
}
