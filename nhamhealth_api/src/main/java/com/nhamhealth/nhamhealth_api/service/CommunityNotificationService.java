package com.nhamhealth.nhamhealth_api.service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;

import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.PostComment;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;

@Service
public class CommunityNotificationService {
    private static final String TYPE = "COMMUNITY";

    private final NotificationRepository notifications;
    private final UserProfileRepository profiles;
    private final PushNotificationService pushNotifications;

    public CommunityNotificationService(NotificationRepository notifications, UserProfileRepository profiles,
            PushNotificationService pushNotifications) {
        this.notifications = notifications;
        this.profiles = profiles;
        this.pushNotifications = pushNotifications;
    }

    public void postLiked(User actor, Post post) {
        send(actor, post.getUser(), "POST", post.getPostId(), "liked your post.");
    }

    public void postCommented(User actor, Post post) {
        send(actor, post.getUser(), "POST", post.getPostId(), "commented on your post.");
    }

    public void postReplyAdded(User actor, Post post) {
        send(actor, post.getUser(), "POST", post.getPostId(), "replied to a comment on your post.");
    }

    public void commentReplied(User actor, PostComment parentComment) {
        send(actor, parentComment.getUser(), "POST", parentComment.getPost().getPostId(),
                "replied to your comment.");
    }

    public void commentLiked(User actor, PostComment comment) {
        send(actor, comment.getUser(), "POST", comment.getPost().getPostId(), "liked your comment.");
    }

    public void postShared(User actor, User recipient, Post post) {
        send(actor, recipient, "POST", post.getPostId(), "shared a community post with you.");
    }

    public void postSharedToFeed(User actor, User recipient, Post sharedPost) {
        send(actor, recipient, "POST", sharedPost.getPostId(), "shared your post.");
    }

    public void followed(User actor, User recipient) {
        send(actor, recipient, "USER", actor.getUserId(), "started following you.");
    }

    private void send(User actor, User recipient, String referenceType, Integer referenceId, String message) {
        if (actor.getUserId().equals(recipient.getUserId())) return;

        Notification notification = new Notification();
        notification.setUser(recipient);
        notification.setActorUser(actor);
        notification.setNotificationType(TYPE);
        notification.setReferenceType(referenceType);
        notification.setReferenceId(referenceId);
        notification.setTitle(actorName(actor));
        notification.setMessage(message);
        notification.setIsRead(false);
        notification.setCreatedAt(LocalDateTime.now());
        pushNotifications.send(notifications.saveAndFlush(notification));
    }

    private String actorName(User actor) {
        return profiles.findByUser_UserId(actor.getUserId())
                .map(UserProfile::getFullName)
                .filter(name -> !name.isBlank())
                .orElseGet(() -> actor.getName() == null || actor.getName().isBlank() ? "Someone" : actor.getName());
    }
}
