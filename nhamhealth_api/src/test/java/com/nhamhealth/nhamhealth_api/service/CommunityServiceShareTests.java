package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import com.nhamhealth.nhamhealth_api.dto.response.CommunityPostResponse;
import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.Share;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.CommentLikeRepository;
import com.nhamhealth.nhamhealth_api.repository.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.PostLikeRepository;
import com.nhamhealth.nhamhealth_api.repository.PostMediaRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.PostTagRepository;
import com.nhamhealth.nhamhealth_api.repository.ShareRepository;
import com.nhamhealth.nhamhealth_api.repository.TagTypeRepository;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

class CommunityServiceShareTests {

    @Test
    void shareToFeedCreatesPostThatReferencesThePublicOriginal() {
        Dependencies dependencies = new Dependencies();
        User owner = user(7, "Original member");
        User actor = user(9, "Sharing member");
        Post original = post(42, owner, "ACTIVE", "PUBLIC");

        when(dependencies.posts.findById(42)).thenReturn(Optional.of(original));
        when(dependencies.users.findById(9)).thenReturn(Optional.of(actor));
        when(dependencies.posts.save(any(Post.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(dependencies.profiles.findByUser_UserId(any())).thenReturn(Optional.empty());
        when(dependencies.media.findByPostPostIdOrderByDisplayOrder(any())).thenReturn(List.of());
        when(dependencies.postTags.findByPostPostIdOrderByPostTagId(any())).thenReturn(List.of());

        CommunityPostResponse response = dependencies.service.shareToFeed(9, 42, "Worth sharing", "FRIENDS");

        ArgumentCaptor<Post> postCaptor = ArgumentCaptor.forClass(Post.class);
        verify(dependencies.posts).save(postCaptor.capture());
        Post saved = postCaptor.getValue();
        assertSame(actor, saved.getUser());
        assertSame(original, saved.getSharedPost());
        assertEquals("Worth sharing", saved.getCaption());
        assertEquals("FRIENDS", saved.getVisibility());
        assertTrue(saved.isAllowComments());
        assertTrue(saved.isAllowReplies());

        ArgumentCaptor<Share> shareCaptor = ArgumentCaptor.forClass(Share.class);
        verify(dependencies.shares).save(shareCaptor.capture());
        Share share = shareCaptor.getValue();
        assertSame(actor, share.getSenderUser());
        assertEquals("POST", share.getReferenceType());
        assertEquals(42, share.getReferenceId());
        assertEquals("COMMUNITY_FEED", share.getSharedVia());
        assertEquals("Original member", response.sharedPost().author());
        verify(dependencies.notifications).postSharedToFeed(actor, owner, saved);
    }

    @Test
    void shareToFeedRejectsNonPublicOriginalPosts() {
        Dependencies dependencies = new Dependencies();
        Post original = post(42, user(7, "Owner"), "ACTIVE", "FRIENDS");
        when(dependencies.posts.findById(42)).thenReturn(Optional.of(original));

        IllegalArgumentException error = assertThrows(IllegalArgumentException.class,
                () -> dependencies.service.shareToFeed(7, 42, "", "PUBLIC"));

        assertEquals("Only public posts can be shared to your feed.", error.getMessage());
        verify(dependencies.posts, never()).save(any(Post.class));
        verify(dependencies.shares, never()).save(any(Share.class));
    }

    @Test
    void sharingAnExistingFeedShareCountsAgainstTheOriginal() {
        Dependencies dependencies = new Dependencies();
        User owner = user(7, "Original member");
        User actor = user(9, "Sharing member");
        Post original = post(42, owner, "ACTIVE", "PUBLIC");
        Post existingShare = post(84, actor, "ACTIVE", "PUBLIC");
        when(existingShare.getSharedPost()).thenReturn(original);
        when(dependencies.posts.findById(84)).thenReturn(Optional.of(existingShare));
        when(dependencies.users.findById(9)).thenReturn(Optional.of(actor));

        dependencies.service.share(9, 84, List.of());

        ArgumentCaptor<Share> shareCaptor = ArgumentCaptor.forClass(Share.class);
        verify(dependencies.shares).save(shareCaptor.capture());
        assertEquals(42, shareCaptor.getValue().getReferenceId());
    }

    private static User user(int id, String name) {
        User user = mock(User.class);
        when(user.getUserId()).thenReturn(id);
        when(user.getName()).thenReturn(name);
        when(user.getRoleLabel()).thenReturn("Member");
        return user;
    }

    private static Post post(int id, User owner, String status, String visibility) {
        Post post = mock(Post.class);
        when(post.getPostId()).thenReturn(id);
        when(post.getUser()).thenReturn(owner);
        when(post.getStatus()).thenReturn(status);
        when(post.getVisibility()).thenReturn(visibility);
        return post;
    }

    private static final class Dependencies {
        private final PostRepository posts = mock(PostRepository.class);
        private final PostMediaRepository media = mock(PostMediaRepository.class);
        private final PostLikeRepository likes = mock(PostLikeRepository.class);
        private final PostCommentRepository comments = mock(PostCommentRepository.class);
        private final CommentLikeRepository commentLikes = mock(CommentLikeRepository.class);
        private final ShareRepository shares = mock(ShareRepository.class);
        private final UserRepository users = mock(UserRepository.class);
        private final UserProfileRepository profiles = mock(UserProfileRepository.class);
        private final FollowRepository follows = mock(FollowRepository.class);
        private final PostTagRepository postTags = mock(PostTagRepository.class);
        private final TagTypeRepository tagTypes = mock(TagTypeRepository.class);
        private final ProfileImageStorageService imageStorage = mock(ProfileImageStorageService.class);
        private final CommunityNotificationService notifications = mock(CommunityNotificationService.class);
        private final CommunityService service = new CommunityService(posts, media, likes, comments,
                commentLikes, shares, users, profiles, follows, postTags, tagTypes, imageStorage, notifications);
    }
}
