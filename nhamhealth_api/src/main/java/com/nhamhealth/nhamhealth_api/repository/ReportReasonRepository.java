package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.ReportReason;

public interface ReportReasonRepository extends JpaRepository<ReportReason, Integer> {
    List<ReportReason> findAllByIsActiveTrueOrderByReasonNameAsc();
}
