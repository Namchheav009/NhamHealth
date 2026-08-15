package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.nhamhealth.nhamhealth_api.entity.PostReport;

public interface PostReportRepository extends JpaRepository<PostReport, Integer> {
    List<PostReport> findAllByOrderByCreatedAtDesc();

    long countByStatusIgnoreCase(String status);

    long countByPostPostIdAndStatusIgnoreCase(Integer postId, String status);
}
