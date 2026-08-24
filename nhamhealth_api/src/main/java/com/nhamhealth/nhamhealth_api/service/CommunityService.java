package com.nhamhealth.nhamhealth_api.service;

import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.time.LocalDateTime;
import java.util.*;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.CommunityPersonResponse;
import com.nhamhealth.nhamhealth_api.dto.response.CommunityPostResponse;
import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.repository.*;

@Service
public class CommunityService {
    private final PostRepository posts;
    private final PostMediaRepository media;
    private final PostLikeRepository likes;
    private final PostCommentRepository comments;
    private final ShareRepository shares;
    private final UserRepository users;
    private final UserProfileRepository profiles;
    private final FollowRepository follows;
    private final ProfileImageStorageService imageStorage;

    public CommunityService(PostRepository posts, PostMediaRepository media,
            PostLikeRepository likes, PostCommentRepository comments, ShareRepository shares,
            UserRepository users, UserProfileRepository profiles, FollowRepository follows,
            ProfileImageStorageService imageStorage) {
        this.posts = posts;
        this.media = media;
        this.likes = likes;
        this.comments = comments;
        this.shares = shares;
        this.users = users;
        this.profiles = profiles;
        this.follows = follows;
        this.imageStorage = imageStorage;
    }

    @Transactional(readOnly = true)
    public List<CommunityPostResponse> posts(Integer viewerId, boolean followingOnly) {
        Set<Integer> followed = followedIds(viewerId);
        return posts.findAllByOrderByUpdatedAtDescCreatedAtDesc().stream()
                .filter(post -> "ACTIVE".equalsIgnoreCase(post.getStatus()))
                .filter(post -> !followingOnly || followed.contains(post.getUser().getUserId())
                        || post.getUser().getUserId().equals(viewerId))
                .map(post -> response(post, viewerId, followed)).toList();
    }

    @Transactional
    public CommunityPostResponse create(Integer userId, String title, String description, MultipartFile image) {
        if (description == null || description.trim().isEmpty()) {
            throw new IllegalArgumentException("Post message is required");
        }
        User user = user(userId);
        LocalDateTime now = LocalDateTime.now();
        Post post = new Post();
        post.setUser(user);
        post.setTitle(title == null || title.isBlank() ? "Community update" : title.trim());
        post.setCaption(description.trim());
        post.setVisibility("PUBLIC");
        post.setStatus("ACTIVE");
        post.setCreatedAt(now);
        post.setUpdatedAt(now);
        post = posts.save(post);
        if (image != null && !image.isEmpty()) {
            PostMedia item = new PostMedia();
            item.setPost(post);
            item.setMediaType("IMAGE");
            item.setMediaUrl(imageStorage.storePostImage(image));
            item.setDisplayOrder(0);
            media.save(item);
        }
        return response(post, userId, followedIds(userId));
    }

    @Transactional
    public CommunityPostResponse toggleLike(Integer userId, Integer postId) {
        Post post = post(postId);
        likes.findByUserUserIdAndPostPostId(userId, postId).ifPresentOrElse(
                likes::delete,
                () -> {
                    PostLike like = new PostLike();
                    like.setUser(user(userId));
                    like.setPost(post);
                    like.setCreatedAt(LocalDateTime.now());
                    likes.save(like);
                });
        return response(post, userId, followedIds(userId));
    }

    @Transactional
    public void share(Integer userId, Integer postId) {
        post(postId);
        Share share = new Share();
        share.setSenderUser(user(userId));
        share.setReferenceType("POST");
        share.setReferenceId(postId);
        share.setSharedVia("COMMUNITY");
        share.setCreatedAt(LocalDateTime.now());
        shares.save(share);
    }

    @Transactional(readOnly = true)
    public List<CommunityPersonResponse> people(Integer viewerId, String view) {
        List<User> all = users.findAll();
        Map<Integer, UserProfile> profileMap = new HashMap<>();
        profiles.findByUser_UserIdIn(all.stream().map(User::getUserId).toList())
                .forEach(profile -> profileMap.put(profile.getUser().getUserId(), profile));
        Set<Integer> following = followedIds(viewerId);
        Set<Integer> followers = followerIds(viewerId);
        return all.stream().filter(user -> !user.getUserId().equals(viewerId))
                .filter(user -> switch (view.toLowerCase(Locale.ROOT)) {
                    case "friends" -> following.contains(user.getUserId()) && followers.contains(user.getUserId());
                    case "followers" -> followers.contains(user.getUserId());
                    case "following" -> following.contains(user.getUserId());
                    default -> true;
                })
                .map(user -> person(user, profileMap.get(user.getUserId()), following, followers)).toList();
    }

    @Transactional
    public String toggleFollow(Integer viewerId, Integer targetId) {
        if (viewerId.equals(targetId)) throw new IllegalArgumentException("You cannot follow yourself");
        Optional<Follow> existing = follows.findByFollowerUserUserIdAndFollowingUserUserId(viewerId, targetId);
        if (existing.isPresent()) {
            follows.delete(existing.get());
            return "NONE";
        }
        Follow follow = new Follow();
        follow.setFollowerUser(user(viewerId));
        follow.setFollowingUser(user(targetId));
        follow.setStatus("ACTIVE");
        follow.setRequestedAt(LocalDateTime.now());
        follow.setRespondedAt(LocalDateTime.now());
        follows.save(follow);
        return "FOLLOWING";
    }

    private CommunityPostResponse response(Post post, Integer viewerId, Set<Integer> followed) {
        UserProfile profile = profiles.findByUser_UserId(post.getUser().getUserId()).orElse(null);
        String imageUrl = media.findByPostPostIdOrderByDisplayOrder(post.getPostId()).stream()
                .findFirst().map(PostMedia::getMediaUrl).orElse("");
        return new CommunityPostResponse(post.getPostId(), value(post.getTitle(), "Community update"),
                value(post.getCaption(), ""), imageUrl, profile == null ? post.getUser().getName() : profile.getFullName(),
                post.getUser().getRoleLabel(), profile == null ? "" : value(profile.getProfileImageUrl(), ""),
                List.of(), post.getCreatedAt(), likes.countByPostPostId(post.getPostId()),
                comments.countByPostPostId(post.getPostId()),
                shares.countByReferenceTypeIgnoreCaseAndReferenceId("POST", post.getPostId()),
                likes.existsByUserUserIdAndPostPostId(viewerId, post.getPostId()),
                followed.contains(post.getUser().getUserId()));
    }

    private CommunityPersonResponse person(User user, UserProfile profile, Set<Integer> following, Set<Integer> followers) {
        boolean mutual = following.contains(user.getUserId()) && followers.contains(user.getUserId());
        String status = mutual ? "FRIEND" : following.contains(user.getUserId()) ? "FOLLOWING" :
                followers.contains(user.getUserId()) ? "FOLLOWS_YOU" : "NONE";
        return new CommunityPersonResponse(user.getUserId(), profile == null ? user.getName() : profile.getFullName(),
                profile == null ? "" : value(profile.getProfileImageUrl(), ""),
                profile == null ? "" : value(profile.getLocationText(), ""), List.of(), mutual ? 1 : 0, status);
    }

    private Set<Integer> followedIds(Integer userId) {
        Set<Integer> ids = new HashSet<>();
        follows.findByFollowerUserUserId(userId).stream().filter(f -> "ACTIVE".equalsIgnoreCase(f.getStatus()))
                .forEach(f -> ids.add(f.getFollowingUser().getUserId()));
        return ids;
    }

    private Set<Integer> followerIds(Integer userId) {
        Set<Integer> ids = new HashSet<>();
        follows.findByFollowingUserUserId(userId).stream().filter(f -> "ACTIVE".equalsIgnoreCase(f.getStatus()))
                .forEach(f -> ids.add(f.getFollowerUser().getUserId()));
        return ids;
    }

    private User user(Integer id) { return users.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found")); }
    private Post post(Integer id) { return posts.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found")); }
    private String value(String value, String fallback) { return value == null || value.isBlank() ? fallback : value; }
}
