package com.nhamhealth.nhamhealth_api.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.nhamhealth.nhamhealth_api.entity.PostReport;

public interface PostReportRepository extends JpaRepository<PostReport, Integer> {
    List<PostReport> findAllByOrderByCreatedAtDesc();

    long countByStatusIgnoreCase(String status);

    long countByPostPostIdAndStatusIgnoreCase(Integer postId, String status);

    @Query("""
            select report.post.postId as postId, count(report) as total
            from PostReport report
            where report.post.postId in :postIds and lower(report.status) = lower(:status)
            group by report.post.postId
            """)
    List<PostCount> countByPostIdsAndStatusIgnoreCase(@Param("postIds") List<Integer> postIds,
            @Param("status") String status);

    interface PostCount {
        Integer getPostId();
        long getTotal();
    }
}
