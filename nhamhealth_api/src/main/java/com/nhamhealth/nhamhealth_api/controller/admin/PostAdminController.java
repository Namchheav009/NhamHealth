package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.Post;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.PostFavoriteRepository;
import com.nhamhealth.nhamhealth_api.repository.PostReportRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class PostAdminController {
    private static final List<String> VALID_STATUSES = List.of("published", "draft", "flagged");
    private static final List<String> VALID_VISIBILITIES = List.of("public", "followers", "private");

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final PostCommentRepository commentRepository;
    private final PostFavoriteRepository favoriteRepository;
    private final PostReportRepository reportRepository;

    public PostAdminController(PostRepository postRepository, UserRepository userRepository,
            PostCommentRepository commentRepository, PostFavoriteRepository favoriteRepository,
            PostReportRepository reportRepository) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.commentRepository = commentRepository;
        this.favoriteRepository = favoriteRepository;
        this.reportRepository = reportRepository;
    }

    @GetMapping("/admin/posts")
    public String postsPage(Authentication authentication, Model model) {
        List<Post> posts = postRepository.findAllByOrderByUpdatedAtDescCreatedAtDesc();
        List<Integer> postIds = posts.stream().map(Post::getPostId).toList();
        Map<Integer, Long> commentCounts = postIds.stream()
                .collect(Collectors.toMap(id -> id, ignored -> 0L));
        if (!postIds.isEmpty()) {
            commentRepository.countByPostIds(postIds)
                    .forEach(count -> commentCounts.put(count.getPostId(), count.getTotal()));
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
        model.addAttribute("favoriteCounts", favoriteCounts);
        model.addAttribute("reportCounts", reportCounts);
        model.addAttribute("totalPosts", posts.size());
        model.addAttribute("activeAuthors", postRepository.countDistinctAuthors());
        model.addAttribute("pendingReports", reportRepository.countByStatusIgnoreCase("pending"));
        return "admin/post";
    }

    @PostMapping("/admin/posts")
    @ResponseBody
    public ResponseEntity<?> createPost(@RequestParam Integer userId, @RequestParam String caption,
            @RequestParam String visibility, @RequestParam String status) {
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return ResponseEntity.badRequest().body(Map.of("message", "Select a valid author."));
        if (caption == null || caption.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Post caption is required."));
        }
        String cleanVisibility = visibility == null ? "" : visibility.trim().toLowerCase();
        String cleanStatus = status == null ? "" : status.trim().toLowerCase();
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
        return ResponseEntity.ok(toResponse(postRepository.saveAndFlush(post)));
    }

    @PatchMapping("/admin/posts/{postId}/status")
    @ResponseBody
    public ResponseEntity<?> updateStatus(@PathVariable Integer postId, @RequestParam String status) {
        String cleanStatus = status == null ? "" : status.trim().toLowerCase();
        if (!VALID_STATUSES.contains(cleanStatus)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select a valid post status."));
        }
        Post post = postRepository.findById(postId).orElse(null);
        if (post == null) return ResponseEntity.notFound().build();
        post.setStatus(cleanStatus);
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
                Map.entry("commentCount", commentRepository.countByPostPostId(post.getPostId())),
                Map.entry("favoriteCount", favoriteRepository.countByPostPostId(post.getPostId())),
                Map.entry("reportCount", reportRepository.countByPostPostIdAndStatusIgnoreCase(post.getPostId(), "pending")),
                Map.entry("updatedAt", post.getUpdatedAt().toString()));
    }
}
