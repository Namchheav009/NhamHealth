package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.*;

import com.nhamhealth.nhamhealth_api.entity.PostLike;
import com.nhamhealth.nhamhealth_api.repository.PostLikeRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class PostLikeAdminController {
    private final PostLikeRepository likes;
    private final UserRepository users;
    private final PostRepository posts;

    public PostLikeAdminController(PostLikeRepository likes, UserRepository users, PostRepository posts) {
        this.likes = likes;
        this.users = users;
        this.posts = posts;
    }

    @GetMapping("/admin/post-likes")
    public String list(Model model) {
        var all = likes.findAllByOrderByCreatedAtDesc();
        model.addAttribute("pageTitle", "Post Likes");
        model.addAttribute("postLikes", all);
        model.addAttribute("totalLikes", all.size());
        model.addAttribute("uniqueUsers", all.stream().map(l -> l.getUser().getUserId()).collect(Collectors.toSet()).size());
        model.addAttribute("likedPosts", all.stream().map(l -> l.getPost().getPostId()).collect(Collectors.toSet()).size());
        model.addAttribute("users", users.findAll());
        model.addAttribute("posts", posts.findAll());
        return "admin/post-likes";
    }

    @PostMapping("/admin/post-likes")
    @ResponseBody
    public ResponseEntity<?> create(@RequestBody Map<String, Object> body) {
        try {
            int userId = Integer.parseInt(String.valueOf(body.get("userId")));
            int postId = Integer.parseInt(String.valueOf(body.get("postId")));
            if (likes.existsByUserUserIdAndPostPostId(userId, postId))
                return ResponseEntity.badRequest().body(Map.of("message", "This user already likes this post."));
            var user = users.findById(userId).orElse(null);
            var post = posts.findById(postId).orElse(null);
            if (user == null || post == null) return ResponseEntity.badRequest().body(Map.of("message", "Select a valid user and post."));
            var like = new PostLike();
            like.setUser(user);
            like.setPost(post);
            like.setCreatedAt(LocalDateTime.now());
            var saved = likes.save(like);
            return ResponseEntity.ok(Map.of("message", "Post like added successfully.", "likeId", saved.getPostLikeId()));
        } catch (RuntimeException ex) {
            return ResponseEntity.badRequest().body(Map.of("message", "Invalid post-like data."));
        }
    }

    @DeleteMapping("/admin/post-likes/{id}")
    @ResponseBody
    public ResponseEntity<Void> delete(@PathVariable Integer id) {
        if (!likes.existsById(id)) return ResponseEntity.notFound().build();
        likes.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
