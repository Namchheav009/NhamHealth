package com.nhamhealth.nhamhealth_api.repository.community;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.UserProfileReport;

public interface UserProfileReportRepository extends JpaRepository<UserProfileReport, Integer> {
    @EntityGraph(attributePaths = {"reportedUser", "reportedByUser", "reportReason", "reviewedByUser"})
    List<UserProfileReport> findAllByOrderByCreatedAtDesc();

    @EntityGraph(attributePaths = {"reportedUser", "reportedByUser", "reportReason", "reviewedByUser"})
    Optional<UserProfileReport> findByProfileReportId(Integer profileReportId);

    long countByStatusIgnoreCase(String status);
}
