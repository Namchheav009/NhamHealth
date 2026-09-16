package com.nhamhealth.nhamhealth_api.service.community;

import static org.springframework.http.HttpStatus.CONFLICT;
import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.time.Clock;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.FollowConnectionResponse;
import com.nhamhealth.nhamhealth_api.entity.Follow;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.community.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

@Service
public class FollowConnectionService {
    private static final String PENDING = Follow.CONNECTION_PENDING;
    private static final String ACCEPTED = Follow.CONNECTION_ACCEPTED;
    private static final String DECLINED = Follow.CONNECTION_DECLINED;
    private final FollowRepository follows;
    private final UserRepository users;
    private final CommunityNotificationService notifications;
    private final Clock clock;

    @Autowired
    public FollowConnectionService(FollowRepository follows,
            UserRepository users, CommunityNotificationService notifications) {
        this(follows, users, notifications, Clock.systemDefaultZone());
    }

    FollowConnectionService(FollowRepository follows,
            UserRepository users, CommunityNotificationService notifications, Clock clock) {
        this.follows = follows;
        this.users = users;
        this.notifications = notifications;
        this.clock = clock;
    }

    @Transactional
    public FollowConnectionResponse create(Integer senderId, Integer receiverId) {
        if (senderId.equals(receiverId)) {
            throw new IllegalArgumentException("You cannot invite yourself.");
        }
        Map<Integer, User> pair = lockPair(senderId, receiverId);
        User sender = pair.get(senderId);
        User receiver = pair.get(receiverId);
        ensureNotBlocked(senderId, receiverId);
        if (areFriends(senderId, receiverId)) {
            throw new ResponseStatusException(CONFLICT, "You are already friends.");
        }

        var pending = follows.findPendingFriendBetweenForUpdate(senderId, receiverId);
        if (pending.isPresent()) {
            Follow existing = pending.get();
            if (existing.getFollowerUser().getUserId().equals(senderId)) {
                throw new ResponseStatusException(CONFLICT, "An invitation is already pending.");
            }
            // A reciprocal request is treated as consent from both members.
            acceptLocked(existing, receiverId, senderId);
            notifications.followConnectionAccepted(sender, receiver, existing.getFollowId());
            return response(existing, "FRIENDS");
        }

        Follow request = new Follow();
        request.setFollowerUser(sender);
        request.setFollowingUser(receiver);
        request.setStatus(PENDING);
        request.setRequestedAt(LocalDateTime.now(clock));
        request = follows.saveAndFlush(request);
        notifications.followConnectionRequested(sender, receiver, request.getFollowId());
        return response(request, "OUTGOING_PENDING");
    }

    @Transactional
    public FollowConnectionResponse accept(Integer receiverId, Integer requestId) {
        Follow snapshot = follows.findById(requestId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Invitation not found."));
        Integer senderId = snapshot.getFollowerUser().getUserId();
        if (!snapshot.getFollowingUser().getUserId().equals(receiverId)) {
            throw new ResponseStatusException(FORBIDDEN, "Only the recipient can accept this request.");
        }
        lockPair(senderId, receiverId);
        Follow request = requiredPending(requestId);
        ensureNotBlocked(senderId, receiverId);
        acceptLocked(request, senderId, receiverId);
        notifications.followConnectionAccepted(request.getFollowingUser(), request.getFollowerUser(), requestId);
        return response(request, "FRIENDS");
    }

    @Transactional
    public FollowConnectionResponse decline(Integer receiverId, Integer requestId) {
        Follow snapshot = follows.findById(requestId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Invitation not found."));
        if (!snapshot.getFollowingUser().getUserId().equals(receiverId)) {
            throw new ResponseStatusException(FORBIDDEN, "Only the recipient can decline this request.");
        }
        lockPair(snapshot.getFollowerUser().getUserId(), receiverId);
        Follow request = requiredPending(requestId);
        request.setStatus(DECLINED);
        request.setRespondedAt(LocalDateTime.now(clock));
        return response(follows.save(request), "NONE");
    }

    @Transactional(readOnly = true)
    public Map<Integer, PendingRelationship> pendingRelationshipsFor(Integer viewerId) {
        Map<Integer, PendingRelationship> result = new HashMap<>();
        for (Follow request : follows.findPendingFriendForUser(viewerId)) {
            boolean outgoing = request.getFollowerUser().getUserId().equals(viewerId);
            Integer otherId = outgoing
                    ? request.getFollowingUser().getUserId()
                    : request.getFollowerUser().getUserId();
            result.put(otherId, new PendingRelationship(
                    outgoing ? "OUTGOING_PENDING" : "INCOMING_PENDING",
                    request.getFollowId()));
        }
        return result;
    }

    private Follow requiredPending(Integer requestId) {
        Follow request = follows.findByIdForUpdate(requestId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Invitation not found."));
        if (!PENDING.equalsIgnoreCase(request.getStatus())) {
            throw new ResponseStatusException(CONFLICT, "This invitation is no longer pending.");
        }
        return request;
    }

    private Map<Integer, User> lockPair(Integer firstId, Integer secondId) {
        List<Integer> ids = List.of(firstId, secondId).stream().sorted().toList();
        List<User> locked = users.findAllByIdForUpdate(ids);
        if (locked.size() != 2) {
            throw new ResponseStatusException(NOT_FOUND, "One of the users was not found.");
        }
        Map<Integer, User> result = new HashMap<>();
        locked.stream().sorted(Comparator.comparing(User::getUserId))
                .forEach(user -> result.put(user.getUserId(), user));
        return result;
    }

    private void ensureNotBlocked(Integer firstId, Integer secondId) {
        if (follows.existsBlockedBetween(firstId, secondId)) {
            throw new ResponseStatusException(FORBIDDEN, "An invitation is unavailable for this user.");
        }
    }

    private boolean areFriends(Integer firstId, Integer secondId) {
        return follows.existsByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCase(
                firstId, secondId, "ACTIVE")
                && follows.existsByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCase(
                        secondId, firstId, "ACTIVE");
    }

    private void acceptLocked(Follow request, Integer firstId, Integer secondId) {
        request.setStatus(ACCEPTED);
        request.setRespondedAt(LocalDateTime.now(clock));
        follows.save(request);
        ensureActiveFollow(firstId, secondId);
        ensureActiveFollow(secondId, firstId);
    }

    private void ensureActiveFollow(Integer followerId, Integer followingId) {
        Follow follow = follows.findFirstByFollowerUserUserIdAndFollowingUserUserIdAndStatusIgnoreCaseOrderByFollowIdAsc(
                followerId, followingId, "ACTIVE")
                .orElseGet(Follow::new);
        if (follow.getFollowerUser() == null) {
            follow.setFollowerUser(users.getReferenceById(followerId));
            follow.setFollowingUser(users.getReferenceById(followingId));
            follow.setRequestedAt(LocalDateTime.now(clock));
        }
        follow.setStatus("ACTIVE");
        follow.setRespondedAt(LocalDateTime.now(clock));
        follows.save(follow);
    }

    private FollowConnectionResponse response(Follow request, String relationshipStatus) {
        return new FollowConnectionResponse(
                request.getFollowId(),
                request.getFollowerUser().getUserId(),
                request.getFollowingUser().getUserId(),
                request.getStatus().substring("FOLLOW_".length()).toUpperCase(),
                relationshipStatus,
                request.getRequestedAt(),
                request.getRespondedAt());
    }

    public record PendingRelationship(String status, Integer requestId) { }
}
