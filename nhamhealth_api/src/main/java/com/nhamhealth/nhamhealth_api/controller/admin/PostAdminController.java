package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.multipart.MultipartFile;

import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.PostMedia;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.PostFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.PostReportRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.PostMediaRepository;
import com.nhamhealth.nhamhealth_api.repository.PostLikeRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.service.ProfileImageStorageService;

@Controller
public class PostAdminController {
    private static final List<String> VALID_STATUSES = List.of("ACTIVE", "HIDDEN", "DELETED");
    private static final List<String> VALID_VISIBILITIES = List.of("PUBLIC", "FRIENDS", "ONLY_ME");
    private static final int MAX_POST_IMAGES = 6;

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final PostCommentRepository commentRepository;
    private final PostFavoriteRepository favoriteRepository;
    private final PostReportRepository reportRepository;
    private final PostMediaRepository mediaRepository;
    private final PostLikeRepository likeRepository;
    private final ProfileImageStorageService imageStorage;

    public PostAdminController(PostRepository postRepository, UserRepository userRepository,
            PostCommentRepository commentRepository, PostFavoriteRepository favoriteRepository,
            PostReportRepository reportRepository, PostMediaRepository mediaRepository,
            PostLikeRepository likeRepository, ProfileImageStorageService imageStorage) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.commentRepository = commentRepository;
        this.favoriteRepository = favoriteRepository;
        this.reportRepository = reportRepository;
        this.mediaRepository = mediaRepository;
        this.likeRepository = likeRepository;
        this.imageStorage = imageStorage;
    }

    @GetMapping("/admin/posts")
    public String postsPage(Authentication authentication, Model model,
            @RequestParam(defaultValue = "0") int page) {
        var postPage = postRepository.findAllByOrderByUpdatedAtDescCreatedAtDesc(
                PageRequest.of(Math.max(page, 0), 20,
                        Sort.by(Sort.Order.desc("updatedAt"), Sort.Order.desc("createdAt"))));
        List<Post> posts = postPage.getContent();
        List<Integer> postIds = posts.stream().map(Post::getPostId).toList();
        Map<Integer, Long> commentCounts = postIds.stream()
                .collect(Collectors.toMap(id -> id, ignored -> 0L));
        if (!postIds.isEmpty()) {
            commentRepository.countByPostIds(postIds)
                    .forEach(count -> commentCounts.put(count.getPostId(), count.getTotal()));
        }
        Map<Integer, Long> likeCounts = postIds.stream()
                .collect(Collectors.toMap(id -> id, ignored -> 0L));
        if (!postIds.isEmpty()) {
            likeRepository.countByPostIds(postIds)
                    .forEach(count -> likeCounts.put(count.getPostId(), count.getTotal()));
        }
        Map<Integer, Long> favoriteCounts = postIds.stream()
                .collect(Collectors.toMap(id -> id, ignored -> 0L));
        if (!postIds.isEmpty()) {
            favoriteRepository.countByPostIds(postIds)
                    .forEach(count -> favoriteCounts.put(count.getPostId(), count.getTotal()));
        }
        Map<Integer, Long> reportCounts = postIds.stream()
                .collect(Collectors.toMap(id -> id, ignored -> 0L));
        if (!postIds.isEmpty()) {
            reportRepository.countByPostIdsAndStatusIgnoreCase(postIds, "pending")
                    .forEach(count -> reportCounts.put(count.getPostId(), count.getTotal()));
        }
        model.addAttribute("pageTitle", "Posts");
        model.addAttribute("activePage", "posts");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("posts", posts);
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("commentCounts", commentCounts);
        model.addAttribute("likeCounts", likeCounts);
        model.addAttribute("favoriteCounts", favoriteCounts);
        model.addAttribute("reportCounts", reportCounts);
        model.addAttribute("totalPosts", postPage.getTotalElements());
        model.addAttribute("postPage", postPage.getNumber());
        model.addAttribute("postTotalPages", postPage.getTotalPages());
        model.addAttribute("activeAuthors", postRepository.countDistinctAuthors());
        model.addAttribute("pendingReports", reportRepository.countByStatusIgnoreCase("pending"));
        return "admin/post";
    }

    @PostMapping("/admin/posts")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> createPost(@RequestParam Integer userId, @RequestParam String caption,
            @RequestParam String visibility, @RequestParam String status,
            @RequestParam(name = "images", required = false) List<MultipartFile> images) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return ResponseEntity.badRequest().body(Map.of("message", "Select a valid author."));
        if (caption == null || caption.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Post caption is required."));
        }
        String cleanVisibility = normalize(visibility);
        String cleanStatus = normalize(status);
        if (!VALID_VISIBILITIES.contains(cleanVisibility) || !VALID_STATUSES.contains(cleanStatus)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select valid visibility and status values."));
        }
        LocalDateTime now = LocalDateTime.now();
        Post post = new Post();
        post.setUser(user);
        post.setCaption(caption.trim());
        post.setVisibility(cleanVisibility);
        post.setStatus(cleanStatus);
        post.setCreatedAt(now);
        post.setUpdatedAt(now);
        post = postRepository.saveAndFlush(post);
        addImages(post, images, 0);
        return ResponseEntity.ok(toResponse(post));
    }

    @PutMapping(value = "/admin/posts/{postId}", consumes = "multipart/form-data")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> updatePost(@PathVariable Integer postId, @RequestParam String caption,
            @RequestParam String visibility, @RequestParam String status,
            @RequestParam(name = "removeImages", defaultValue = "false") boolean removeImages,
            @RequestParam(name = "images", required = false) List<MultipartFile> images) {
        if (caption == null || caption.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Post caption is required."));
        }
        String cleanVisibility = normalize(visibility);
        String cleanStatus = normalize(status);
        if (!VALID_VISIBILITIES.contains(cleanVisibility) || !VALID_STATUSES.contains(cleanStatus)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select valid visibility and status values."));
        }
        Post post = postRepository.findById(postId).orElse(null);
        if (post == null) return ResponseEntity.notFound().build();
        List<PostMedia> existing = mediaRepository.findByPostPostIdOrderByDisplayOrder(postId);
        List<MultipartFile> uploads = usableImages(images);
        if (removeImages) {
            mediaRepository.deleteAll(existing);
            existing = List.of();
        }
        validateImageCount(existing.size() + uploads.size());
        post.setCaption(caption.trim());
        post.setVisibility(cleanVisibility);
        post.setStatus(cleanStatus);
        post.setUpdatedAt(LocalDateTime.now());
        post = postRepository.saveAndFlush(post);
        addImages(post, uploads, existing.size());
        return ResponseEntity.ok(toResponse(post));
    }

    @DeleteMapping("/admin/posts/{postId}")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> deletePost(@PathVariable Integer postId) {
        Post post = postRepository.findById(postId).orElse(null);
        if (post == null) return ResponseEntity.notFound().build();
        post.setStatus("DELETED");
        post.setUpdatedAt(LocalDateTime.now());
        return ResponseEntity.ok(toResponse(postRepository.saveAndFlush(post)));
    }

    private Map<String, Object> toResponse(Post post) {
        String name = post.getUser().getName();
        String email = post.getUser().getEmail();
        return Map.ofEntries(
                Map.entry("id", post.getPostId()), Map.entry("userId", post.getUser().getUserId()),
                Map.entry("authorName", name == null || name.isBlank() ? "Unknown user" : name),
                Map.entry("authorEmail", email == null ? "" : email), Map.entry("caption", post.getCaption()),
                Map.entry("visibility", post.getVisibility()), Map.entry("status", post.getStatus()),
                Map.entry("imageUrls", mediaRepository.findByPostPostIdOrderByDisplayOrder(post.getPostId()).stream()
                        .map(PostMedia::getMediaUrl).toList()),
                Map.entry("commentCount", commentRepository.countByPostPostId(post.getPostId())),
                Map.entry("likeCount", likeRepository.countByPostPostId(post.getPostId())),
                Map.entry("favoriteCount", favoriteRepository.countByPostPostId(post.getPostId())),
                Map.entry("reportCount", reportRepository.countByPostPostIdAndStatusIgnoreCase(post.getPostId(), "pending")),
                Map.entry("updatedAt", post.getUpdatedAt().toString()));
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim().toUpperCase();
    }

    private List<MultipartFile> usableImages(List<MultipartFile> images) {
        return images == null ? List.of() : images.stream()
                .filter(image -> image != null && !image.isEmpty()).toList();
    }

    private void validateImageCount(int count) {
        if (count > MAX_POST_IMAGES) {
            throw new IllegalArgumentException("A post can have at most " + MAX_POST_IMAGES + " images.");
        }
    }

    private void addImages(Post post, List<MultipartFile> images, int displayOrder) {
        for (int index = 0; index < images.size(); index++) {
            PostMedia item = new PostMedia();
            item.setPost(post);
            item.setMediaType("IMAGE");
            item.setMediaUrl(imageStorage.storePostImage(images.get(index)));
            item.setDisplayOrder(displayOrder + index);
            mediaRepository.save(item);
        }
    }
}
