package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.PostComment;
import com.nhamhealth.nhamhealth_api.repository.community.CommentLikeRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostCommentRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

@Controller
public class CommentAdminController {
    private final PostCommentRepository comments;
    private final CommentLikeRepository likes;
    private final UserRepository users;
    private final PostRepository posts;

    public CommentAdminController(PostCommentRepository comments, CommentLikeRepository likes,
            UserRepository users, PostRepository posts) {
        this.comments = comments;
        this.likes = likes;
        this.users = users;
        this.posts = posts;
    }

    @GetMapping("/admin/comments")
    public String list(Model model) {
        var all = comments.findAllByOrderByCreatedAtDesc();
        model.addAttribute("pageTitle", "Comments");
        model.addAttribute("comments", all);
        model.addAttribute("totalComments", all.size());
        model.addAttribute("activeComments", all.stream().filter(c -> "active".equalsIgnoreCase(c.getStatus())).count());
        model.addAttribute("hiddenComments", all.stream().filter(c -> !"active".equalsIgnoreCase(c.getStatus())).count());
        model.addAttribute("commentLikeCounts", all.stream().collect(java.util.stream.Collectors.toMap(
                PostComment::getCommentId, c -> likes.countByPostCommentCommentId(c.getCommentId()))));
        model.addAttribute("users", users.findAll());
        model.addAttribute("posts", posts.findAll());
        return "admin/comments";
    }

    @PostMapping("/admin/comments")
    @ResponseBody
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        return save(new PostComment(), body, true);
    }

    @PutMapping("/admin/comments/{id}")
    @ResponseBody
    public ResponseEntity<?> update(@PathVariable Integer id, @RequestBody Map<String, Object> body) {
        var comment = comments.findById(id).orElse(null);
        return comment == null ? ResponseEntity.notFound().build() : save(comment, body, false);
    }

    private ResponseEntity<?> save(PostComment comment, Map<String, Object> body, boolean creating) {
        try {
            var text = String.valueOf(body.getOrDefault("commentText", "")).trim();
            var status = String.valueOf(body.getOrDefault("status", "active")).toLowerCase();
            if (text.isBlank()) return ResponseEntity.badRequest().body(Map.of("message", "Comment text is required."));
            if (!java.util.Set.of("active", "hidden", "deleted").contains(status))
                return ResponseEntity.badRequest().body(Map.of("message", "Invalid comment status."));
            if (creating) {
                var user = users.findById(Integer.valueOf(String.valueOf(body.get("userId")))).orElse(null);
                var post = posts.findById(Integer.valueOf(String.valueOf(body.get("postId")))).orElse(null);
                if (user == null || post == null) return ResponseEntity.badRequest().body(Map.of("message", "Select a valid user and post."));
                comment.setUser(user);
                comment.setPost(post);
                comment.setCreatedAt(LocalDateTime.now());
            }
            comment.setCommentText(text);
            comment.setStatus(status);
            comment.setUpdatedAt(LocalDateTime.now());
            var saved = comments.save(comment);
            return ResponseEntity.ok(Map.of("message", "Comment saved successfully.", "commentId", saved.getCommentId()));
        } catch (RuntimeException ex) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid comment data."));
        }
    }

    @DeleteMapping("/admin/comments/{id}")
    @ResponseBody
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        if (!comments.existsById(id)) return ResponseEntity.notFound().build();
        comments.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
