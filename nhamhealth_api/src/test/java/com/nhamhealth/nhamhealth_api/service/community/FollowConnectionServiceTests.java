package com.nhamhealth.nhamhealth_api.service.community;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.time.Clock;
import java.time.Instant;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.entity.Follow;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.community.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

class FollowConnectionServiceTests {
    private final FollowRepository follows = mock(FollowRepository.class);
    private final UserRepository users = mock(UserRepository.class);
    private final CommunityNotificationService notifications = mock(CommunityNotificationService.class);
    private final Clock clock = Clock.fixed(Instant.parse("2026-09-16T08:00:00Z"), ZoneOffset.UTC);
    private final User sender = user(1);
    private final User receiver = user(2);
    private final FollowConnectionService service = new FollowConnectionService(
            follows, users, notifications, clock);

    @BeforeEach
    void lockUsers() {
        when(users.findAllByIdForUpdate(List.of(1, 2))).thenReturn(List.of(sender, receiver));
        when(users.getReferenceById(1)).thenReturn(sender);
        when(users.getReferenceById(2)).thenReturn(receiver);
        when(follows.saveAndFlush(any(Follow.class))).thenAnswer(invocation -> {
            Follow request = invocation.getArgument(0);
            ReflectionTestUtils.setField(request, "followId", 41);
            return request;
        });
    }

    @Test
    void createsSingleRequestForSampleReceiverIdTwo() {
        when(follows.findPendingFriendBetweenForUpdate(1, 2)).thenReturn(Optional.empty());

        var result = service.create(1, 2);

        assertEquals(2, result.receiverId());
        assertEquals("PENDING", result.status());
        assertEquals("OUTGOING_PENDING", result.relationshipStatus());
        org.mockito.ArgumentCaptor<Follow> saved = org.mockito.ArgumentCaptor.forClass(Follow.class);
        verify(follows).saveAndFlush(saved.capture());
        assertEquals("FOLLOW_PENDING", saved.getValue().getStatus());
        verify(notifications).followConnectionRequested(sender, receiver, 41);
    }

    @Test
    void rejectsDuplicateOutgoingRequest() {
        Follow pending = request(7, sender, receiver, "FOLLOW_PENDING");
        when(follows.findPendingFriendBetweenForUpdate(1, 2)).thenReturn(Optional.of(pending));

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class, () -> service.create(1, 2));

        assertEquals(409, error.getStatusCode().value());
        verify(follows, never()).saveAndFlush(any());
        verify(notifications, never()).followConnectionRequested(any(), any(), any());
    }

    @Test
    void reciprocalPendingRequestIsAcceptedWithoutSecondRequest() {
        Follow pending = request(7, sender, receiver, "FOLLOW_PENDING");
        when(follows.findPendingFriendBetweenForUpdate(2, 1)).thenReturn(Optional.of(pending));

        var result = service.create(2, 1);

        assertEquals("ACCEPTED", result.status());
        assertEquals("FRIENDS", result.relationshipStatus());
        assertEquals("FOLLOW_ACCEPTED", pending.getStatus());
        verify(follows, never()).saveAndFlush(any());
        verify(follows, org.mockito.Mockito.times(3)).save(any());
        verify(notifications).followConnectionAccepted(receiver, sender, 7);
    }

    @Test
    void blockedPairCannotCreateRequest() {
        when(follows.existsBlockedBetween(1, 2)).thenReturn(true);

        ResponseStatusException error = assertThrows(
                ResponseStatusException.class, () -> service.create(1, 2));

        assertEquals(403, error.getStatusCode().value());
        verify(follows, never()).saveAndFlush(any());
        verify(notifications, never()).followConnectionRequested(any(), any(), any());
    }

    @Test
    void existingOneWayFollowRemainsActiveWhenConnectionIsCreated() {
        Follow active = request(90, sender, receiver, "ACTIVE");
        when(follows.existsByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCase(
                1, 2, "ACTIVE")).thenReturn(true);
        when(follows.findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
                1, 2, "ACTIVE")).thenReturn(Optional.of(active));

        var result = service.create(1, 2);

        assertEquals("OUTGOING_PENDING", result.relationshipStatus());
        assertEquals("ACTIVE", active.getStatus());
        verify(follows, never()).save(active);
    }

    @Test
    void pendingRelationshipReadsTheFollowEvent() {
        when(follows.findPendingFriendForUser(1)).thenReturn(List.of(
                request(7, sender, receiver, "FOLLOW_PENDING")));

        var relationships = service.pendingRelationshipsFor(1);

        assertEquals("OUTGOING_PENDING", relationships.get(2).status());
        assertEquals(7, relationships.get(2).requestId());
    }

    @Test
    void recipientCanAcceptAndCreateTheExistingFriendRepresentation() {
        Follow pending = request(12, sender, receiver, "FOLLOW_PENDING");
        when(follows.findById(12)).thenReturn(Optional.of(pending));
        when(follows.findByIdForUpdate(12)).thenReturn(Optional.of(pending));

        var result = service.accept(2, 12);

        assertEquals("FRIENDS", result.relationshipStatus());
        assertEquals("FOLLOW_ACCEPTED", pending.getStatus());
        verify(follows, org.mockito.Mockito.times(3)).save(any());
        verify(notifications).followConnectionAccepted(receiver, sender, 12);
    }

    @Test
    void recipientCanDeclineWithoutCreatingFollows() {
        Follow pending = request(13, sender, receiver, "FOLLOW_PENDING");
        when(follows.findById(13)).thenReturn(Optional.of(pending));
        when(follows.findByIdForUpdate(13)).thenReturn(Optional.of(pending));
        when(follows.save(pending)).thenReturn(pending);

        var result = service.decline(2, 13);

        assertEquals("NONE", result.relationshipStatus());
        assertEquals("FOLLOW_DECLINED", pending.getStatus());
        verify(follows, org.mockito.Mockito.times(1)).save(any());
    }

    @Test
    void selfRequestIsRejectedBeforeDatabaseWork() {
        assertThrows(IllegalArgumentException.class, () -> service.create(1, 1));
        verify(users, never()).findAllByIdForUpdate(any());
    }

    private static Follow request(int id, User from, User to, String status) {
        Follow request = new Follow();
        ReflectionTestUtils.setField(request, "followId", id);
        request.setFollowerUser(from);
        request.setFollowingUser(to);
        request.setStatus(status);
        request.setRequestedAt(java.time.LocalDateTime.of(2026, 9, 16, 8, 0));
        return request;
    }

    private static User user(int id) {
        User user = mock(User.class);
        when(user.getUserId()).thenReturn(id);
        return user;
    }
}
