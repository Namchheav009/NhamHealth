package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.PostReport;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.PostReportRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.ReportReasonRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

class CommunityReportServiceTests {

    @Test
    void reviewLoadsTheAdminResponseGraphBeforeReturning() {
        PostRepository posts = mock(PostRepository.class);
        PostCommentRepository comments = mock(PostCommentRepository.class);
        PostReportRepository reports = mock(PostReportRepository.class);
        ReportReasonRepository reasons = mock(ReportReasonRepository.class);
        UserRepository users = mock(UserRepository.class);
        NotificationRepository notifications = mock(NotificationRepository.class);
        CommunityReportService service = new CommunityReportService(
                posts, comments, reports, reasons, users, notifications);
        PostReport report = new PostReport();

        when(reports.findByReportId(12)).thenReturn(Optional.of(report));
        when(reports.saveAndFlush(report)).thenReturn(report);

        PostReport reviewed = service.review(12, "under_review", "none", null, mock(User.class));

        assertEquals("under_review", reviewed.getStatus());
        verify(reports).findByReportId(12);
    }
}
