package com.nhamhealth.nhamhealth_api.service;

import static org.springframework.http.HttpStatus.FORBIDDEN;
import static org.springframework.http.HttpStatus.NOT_FOUND;

import java.time.LocalDateTime;
import java.util.*;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.CommunityPersonResponse;
import com.nhamhealth.nhamhealth_api.dto.response.CommunityCommentResponse;
import com.nhamhealth.nhamhealth_api.dto.response.CommunityPostResponse;
import com.nhamhealth.nhamhealth_api.dto.response.CommunityTagResponse;
import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.repository.*;

@Service
public class CommunityService {
    private static final int MAX_POST_IMAGES = 6;
    private final PostRepository posts;
    private final PostMediaRepository media;
    private final PostLikeRepository likes;
    private final PostCommentRepository comments;
    private final CommentLikeRepository commentLikes;
    private final ShareRepository shares;
    private final UserRepository users;
    private final UserProfileRepository profiles;
    private final FollowRepository follows;
    private final PostTagRepository postTags;
    private final TagTypeRepository tagTypes;
    private final ProfileImageStorageService imageStorage;
    private final CommunityNotificationService communityNotifications;

    public CommunityService(PostRepository posts, PostMediaRepository media,
            PostLikeRepository likes, PostCommentRepository comments, CommentLikeRepository commentLikes,
            ShareRepository shares,
            UserRepository users, UserProfileRepository profiles, FollowRepository follows,
            PostTagRepository postTags, TagTypeRepository tagTypes,
            ProfileImageStorageService imageStorage,
            CommunityNotificationService communityNotifications) {
        this.posts = posts;
        this.media = media;
        this.likes = likes;
        this.comments = comments;
        this.commentLikes = commentLikes;
        this.shares = shares;
        this.users = users;
        this.profiles = profiles;
        this.follows = follows;
        this.postTags = postTags;
        this.tagTypes = tagTypes;
        this.imageStorage = imageStorage;
        this.communityNotifications = communityNotifications;
    }

    @Transactional(readOnly = true)
    public List<CommunityPostResponse> posts(Integer viewerId, boolean followingOnly) {
        Set<Integer> followed = followedIds(viewerId);
        Set<Integer> followers = followerIds(viewerId);
        return posts.findAllByOrderByUpdatedAtDescCreatedAtDesc().stream()
                .filter(post -> "ACTIVE".equalsIgnoreCase(post.getStatus()))
                .filter(post -> canView(post, viewerId, followed, followers))
                .filter(post -> !followingOnly || followed.contains(post.getUser().getUserId())
                        || post.getUser().getUserId().equals(viewerId))
                .map(post -> response(post, viewerId, followed)).toList();
    }

    @Transactional(readOnly = true)
    public List<CommunityPostResponse> myPosts(Integer userId) {
        Set<Integer> followed = followedIds(userId);
        return posts
                .findByUser_UserIdAndStatusIgnoreCaseOrderByUpdatedAtDescCreatedAtDesc(userId, "ACTIVE")
                .stream().map(post -> response(post, userId, followed)).toList();
    }

    @Transactional(readOnly = true)
    public List<CommunityTagResponse> tags() {
        return tagTypes.findAllByOrderByTagNameAsc().stream()
                .filter(tag -> Boolean.TRUE.equals(tag.getIsActive()))
                .map(tag -> new CommunityTagResponse(tag.getTagId(), tag.getTagName(),
                        tag.getTagScope(), value(tag.getDescription(), "")))
                .toList();
    }

    @Transactional
    public CommunityPostResponse create(Integer userId, String title, String description, String visibility,
            boolean allowComments, boolean allowReplies, List<Integer> tagIds, List<MultipartFile> images) {
        if (description == null || description.trim().isEmpty()) {
            throw new IllegalArgumentException("Post message is required");
        }
        User user = user(userId);
        LocalDateTime now = LocalDateTime.now();
        Post post = new Post();
        post.setUser(user);
        post.setTitle(title == null || title.isBlank() ? "Community update" : title.trim());
        post.setCaption(description.trim());
        post.setVisibility(cleanVisibility(visibility));
        post.setAllowComments(allowComments);
        post.setAllowReplies(allowComments && allowReplies);
        post.setStatus("ACTIVE");
        post.setCreatedAt(now);
        post.setUpdatedAt(now);
        post = posts.save(post);
        replaceTags(post, tagIds);
        List<MultipartFile> uploads = usableImages(images);
        validateImageCount(uploads.size());
        for (int index = 0; index < uploads.size(); index++) {
            PostMedia item = new PostMedia();
            item.setPost(post);
            item.setMediaType("IMAGE");
            item.setMediaUrl(imageStorage.storePostImage(uploads.get(index)));
            item.setDisplayOrder(index);
            media.save(item);
        }
        return response(post, userId, followedIds(userId));
    }

    @Transactional
    public CommunityPostResponse update(Integer userId, Integer postId, String title, String description,
            String visibility, boolean allowComments, boolean allowReplies, boolean removeImage,
            List<Integer> tagIds, List<MultipartFile> images, boolean replaceWithLegacyImage) {
        if (description == null || description.trim().isEmpty()) {
            throw new IllegalArgumentException("Post message is required");
        }
        Post post = ownedPost(userId, postId);
        post.setTitle(title == null || title.isBlank() ? "Community update" : title.trim());
        post.setCaption(description.trim());
        post.setVisibility(cleanVisibility(visibility));
        post.setAllowComments(allowComments);
        post.setAllowReplies(allowComments && allowReplies);
        post.setUpdatedAt(LocalDateTime.now());
        replaceTags(post, tagIds);
        List<MultipartFile> uploads = usableImages(images);
        if (removeImage || replaceWithLegacyImage) {
            media.deleteAll(media.findByPostPostIdOrderByDisplayOrder(postId));
        }
        List<PostMedia> existingMedia = media.findByPostPostIdOrderByDisplayOrder(postId);
        validateImageCount(existingMedia.size() + uploads.size());
        for (int index = 0; index < uploads.size(); index++) {
            PostMedia item = new PostMedia();
            item.setPost(post);
            item.setMediaType("IMAGE");
            item.setMediaUrl(imageStorage.storePostImage(uploads.get(index)));
            item.setDisplayOrder(existingMedia.size() + index);
            media.save(item);
        }
        return response(posts.save(post), userId, followedIds(userId));
    }

    @Transactional
    public void delete(Integer userId, Integer postId) {
        Post post = ownedPost(userId, postId);
        post.setStatus("DELETED");
        post.setUpdatedAt(LocalDateTime.now());
        posts.save(post);
    }

    @Transactional
    public CommunityPostResponse toggleLike(Integer userId, Integer postId) {
        Post post = post(postId);
        Optional<PostLike> existing = likes.findByUserUserIdAndPostPostId(userId, postId);
        if (existing.isPresent()) {
            likes.delete(existing.get());
        } else {
            User actor = user(userId);
            PostLike like = new PostLike();
            like.setUser(actor);
            like.setPost(post);
            like.setCreatedAt(LocalDateTime.now());
            likes.save(like);
            communityNotifications.postLiked(actor, post);
        }
        return response(post, userId, followedIds(userId));
    }

    @Transactional
    public void share(Integer userId, Integer postId, List<Integer> recipientIds) {
        Post post = post(postId);
        User actor = user(userId);
        Set<Integer> recipients = recipientIds == null ? Set.of() : new LinkedHashSet<>(recipientIds);
        if (!recipients.isEmpty()) {
            Set<Integer> friends = followedIds(userId);
            friends.retainAll(followerIds(userId));
            if (!friends.containsAll(recipients)) {
                throw new IllegalArgumentException("Posts can only be shared with your friends.");
            }
        }
        if (recipients.isEmpty()) {
            saveShare(actor, post, null);
            return;
        }
        for (Integer recipientId : recipients) {
            saveShare(actor, post, recipientId);
        }
    }

    private void saveShare(User actor, Post post, Integer recipientId) {
        Share share = new Share();
        share.setSenderUser(actor);
        User recipient = recipientId == null ? null : user(recipientId);
        if (recipient != null) share.setReceiverUser(recipient);
        share.setReferenceType("POST");
        share.setReferenceId(post.getPostId());
        share.setSharedVia("COMMUNITY");
        share.setCreatedAt(LocalDateTime.now());
        shares.save(share);
        if (recipient != null) communityNotifications.postShared(actor, recipient, post);
    }

    @Transactional(readOnly = true)
    public List<CommunityCommentResponse> comments(Integer userId, Integer postId) {
        post(postId);
        return comments.findByPostPostIdAndStatusIgnoreCaseOrderByCreatedAtAsc(postId, "ACTIVE")
                .stream().map(comment -> commentResponse(comment, userId)).toList();
    }

    @Transactional
    public CommunityCommentResponse comment(Integer userId, Integer postId, String text, Integer parentCommentId) {
        if (text == null || text.trim().isEmpty()) {
            throw new IllegalArgumentException("Comment text is required");
        }
        Post post = post(postId);
        if (!post.isAllowComments()) {
            throw new IllegalArgumentException("Comments are disabled for this post");
        }
        User actor = user(userId);
        PostComment comment = new PostComment();
        comment.setPost(post);
        comment.setUser(actor);
        PostComment parent = null;
        if (parentCommentId != null) {
            if (!post.isAllowReplies()) {
                throw new IllegalArgumentException("Replies are disabled for this post");
            }
            parent = comments.findById(parentCommentId)
                    .orElseThrow(() -> new IllegalArgumentException("The comment you are replying to was not found"));
            if (!parent.getPost().getPostId().equals(postId) || !"ACTIVE".equalsIgnoreCase(parent.getStatus())) {
                throw new IllegalArgumentException("Replies must belong to an active comment on this post");
            }
            comment.setParentComment(parent);
        }
        comment.setCommentText(text.trim());
        comment.setStatus("ACTIVE");
        comment.setCreatedAt(LocalDateTime.now());
        comment.setUpdatedAt(comment.getCreatedAt());
        PostComment saved = comments.save(comment);
        if (parent == null) {
            communityNotifications.postCommented(actor, post);
        } else {
            communityNotifications.commentReplied(actor, parent);
            if (!post.getUser().getUserId().equals(parent.getUser().getUserId())) {
                communityNotifications.postReplyAdded(actor, post);
            }
        }
        return commentResponse(saved);
    }

    @Transactional
    public CommunityCommentResponse toggleCommentLike(Integer userId, Integer postId, Integer commentId) {
        PostComment comment = comments.findById(commentId)
                .orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Comment not found"));
        if (!comment.getPost().getPostId().equals(postId) || !"ACTIVE".equalsIgnoreCase(comment.getStatus())) {
            throw new ResponseStatusException(NOT_FOUND, "Comment not found");
        }
        Optional<CommentLike> existing = commentLikes.findByUserUserIdAndPostCommentCommentId(userId, commentId);
        if (existing.isPresent()) {
            commentLikes.delete(existing.get());
        } else {
            User actor = user(userId);
            CommentLike like = new CommentLike();
            like.setUser(actor);
            like.setPostComment(comment);
            like.setCreatedAt(LocalDateTime.now());
            commentLikes.save(like);
            communityNotifications.commentLiked(actor, comment);
        }
        return commentResponse(comment, userId);
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
        communityNotifications.followed(follow.getFollowerUser(), follow.getFollowingUser());
        return "FOLLOWING";
    }

    private CommunityPostResponse response(Post post, Integer viewerId, Set<Integer> followed) {
        UserProfile profile = profiles.findByUser_UserId(post.getUser().getUserId()).orElse(null);
        List<String> imageUrls = media.findByPostPostIdOrderByDisplayOrder(post.getPostId()).stream()
                .map(PostMedia::getMediaUrl).toList();
        String imageUrl = imageUrls.isEmpty() ? "" : imageUrls.getFirst();
        List<PostTag> assignedTags = postTags.findByPostPostIdOrderByPostTagId(post.getPostId());
        return new CommunityPostResponse(post.getPostId(), value(post.getTitle(), "Community update"),
                value(post.getCaption(), ""), imageUrl, imageUrls, post.getUser().getUserId(),
                profile == null ? post.getUser().getName() : profile.getFullName(),
                post.getUser().getRoleLabel(), profile == null ? "" : value(profile.getProfileImageUrl(), ""),
                assignedTags.stream().map(item -> item.getTag().getTagName()).toList(), post.getCreatedAt(), likes.countByPostPostId(post.getPostId()),
                comments.countByPostPostIdAndStatusIgnoreCase(post.getPostId(), "ACTIVE"),
                shares.countByReferenceTypeIgnoreCaseAndReferenceId("POST", post.getPostId()),
                likes.existsByUserUserIdAndPostPostId(viewerId, post.getPostId()),
                followed.contains(post.getUser().getUserId()), post.getVisibility(),
                post.isAllowComments(), post.isAllowReplies(),
                assignedTags.stream().map(item -> item.getTag().getTagId()).toList());
    }

    private CommunityCommentResponse commentResponse(PostComment comment) {
        return commentResponse(comment, null);
    }

    private CommunityCommentResponse commentResponse(PostComment comment, Integer viewerId) {
        UserProfile profile = profiles.findByUser_UserId(comment.getUser().getUserId()).orElse(null);
        return new CommunityCommentResponse(comment.getCommentId(),
                profile == null ? comment.getUser().getName() : profile.getFullName(),
                profile == null ? "" : value(profile.getProfileImageUrl(), ""),
                comment.getCommentText(), comment.getCreatedAt(),
                comment.getParentComment() == null ? null : comment.getParentComment().getCommentId(),
                commentLikes.countByPostCommentCommentId(comment.getCommentId()),
                viewerId != null && commentLikes.existsByUserUserIdAndPostCommentCommentId(viewerId, comment.getCommentId()));
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

    private boolean canView(Post post, Integer viewerId, Set<Integer> followed, Set<Integer> followers) {
        if (post.getUser().getUserId().equals(viewerId)) return true;
        return switch (value(post.getVisibility(), "PUBLIC").toUpperCase(Locale.ROOT)) {
            case "ONLY_ME" -> false;
            case "FRIENDS" -> followed.contains(post.getUser().getUserId())
                    && followers.contains(post.getUser().getUserId());
            default -> true;
        };
    }

    private String cleanVisibility(String visibility) {
        String clean = value(visibility, "PUBLIC").toUpperCase(Locale.ROOT);
        if (Set.of("PUBLIC", "FRIENDS", "ONLY_ME").contains(clean)) return clean;
        throw new IllegalArgumentException("Select a valid audience");
    }

    private void replaceTags(Post post, List<Integer> rawTagIds) {
        Set<Integer> tagIds = rawTagIds == null ? Set.of()
                : rawTagIds.stream().filter(Objects::nonNull).collect(java.util.stream.Collectors.toCollection(LinkedHashSet::new));
        List<TagType> tags = tagIds.isEmpty() ? List.of() : tagTypes.findAllById(tagIds);
        if (tags.size() != tagIds.size() || tags.stream().anyMatch(tag -> !Boolean.TRUE.equals(tag.getIsActive()))) {
            throw new IllegalArgumentException("Choose active tags only");
        }
        postTags.deleteByPostPostId(post.getPostId());
        postTags.saveAll(tags.stream().map(tag -> {
            PostTag postTag = new PostTag();
            postTag.setPost(post);
            postTag.setTag(tag);
            return postTag;
        }).toList());
    }

    private List<MultipartFile> usableImages(List<MultipartFile> images) {
        if (images == null) return List.of();
        return images.stream().filter(Objects::nonNull).filter(image -> !image.isEmpty()).toList();
    }

    private void validateImageCount(int count) {
        if (count > MAX_POST_IMAGES) {
            throw new IllegalArgumentException("A post can include up to " + MAX_POST_IMAGES + " images");
        }
    }

    private User user(Integer id) { return users.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "User not found")); }
    private Post post(Integer id) { return posts.findById(id).orElseThrow(() -> new ResponseStatusException(NOT_FOUND, "Post not found")); }
    private Post ownedPost(Integer userId, Integer postId) {
        Post post = post(postId);
        if (!post.getUser().getUserId().equals(userId)) {
            throw new ResponseStatusException(FORBIDDEN, "You can only edit or delete your own posts.");
        }
        return post;
    }
    private String value(String value, String fallback) { return value == null || value.isBlank() ? fallback : value; }
}
