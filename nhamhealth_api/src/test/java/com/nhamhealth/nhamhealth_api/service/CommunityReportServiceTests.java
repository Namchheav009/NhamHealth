package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.PostReport;
import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.Notification;
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
        PushNotificationService pushNotifications = mock(PushNotificationService.class);
        CommunityReportService service = new CommunityReportService(
                posts, comments, reports, reasons, users, notifications, pushNotifications);
        PostReport report = new PostReport();

        when(reports.findByReportId(12)).thenReturn(Optional.of(report));
        when(reports.saveAndFlush(report)).thenReturn(report);

        PostReport reviewed = service.review(12, "under_review", "none", null, mock(User.class));

        assertEquals("under_review", reviewed.getStatus());
        verify(reports).findByReportId(12);
    }

    @Test
    void moderationNotificationsArePushedAfterTheyArePersisted() {
        PostRepository posts = mock(PostRepository.class);
        PostCommentRepository comments = mock(PostCommentRepository.class);
        PostReportRepository reports = mock(PostReportRepository.class);
        ReportReasonRepository reasons = mock(ReportReasonRepository.class);
        UserRepository users = mock(UserRepository.class);
        NotificationRepository notifications = mock(NotificationRepository.class);
        PushNotificationService pushNotifications = mock(PushNotificationService.class);
        CommunityReportService service = new CommunityReportService(
                posts, comments, reports, reasons, users, notifications, pushNotifications);
        PostReport report = new PostReport();
        Post post = mock(Post.class);
        User reporter = mock(User.class);
        User reviewer = mock(User.class);

        report.setPost(post);
        report.setReportedByUser(reporter);
        report.setTargetType("POST");
        when(post.getPostId()).thenReturn(44);
        when(reports.findByReportId(12)).thenReturn(Optional.of(report));
        when(reports.saveAndFlush(report)).thenReturn(report);
        when(notifications.saveAndFlush(any(Notification.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        service.review(12, "dismissed", "keep", null, reviewer);

        var notification = org.mockito.ArgumentCaptor.forClass(Notification.class);
        verify(pushNotifications).send(notification.capture());
        assertSame(reporter, notification.getValue().getUser());
        assertEquals("MODERATION", notification.getValue().getNotificationType());
        assertEquals("POST", notification.getValue().getReferenceType());
        assertEquals(44, notification.getValue().getReferenceId());
    }
}
