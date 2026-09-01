package com.nhamhealth.nhamhealth_api.repository.community;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.ReportReason;

public interface ReportReasonRepository extends JpaRepository<ReportReason, Integer> {
    List<ReportReason> findAllByIsActiveTrueOrderByReportReasonIdAsc();

    List<ReportReason> findAllByIsActiveTrueOrderByReasonNameAsc();

    boolean existsByReasonNameIgnoreCase(String reasonName);
}
