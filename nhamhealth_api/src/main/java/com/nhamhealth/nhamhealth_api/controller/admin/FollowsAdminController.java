package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.Follow;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.community.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

@Controller
public class FollowsAdminController {
    private static final List<String> VALID_STATUSES = List.of("active", "blocked");

    private final FollowRepository followRepository;
    private final UserRepository userRepository;

    public FollowsAdminController(FollowRepository followRepository, UserRepository userRepository) {
        this.followRepository = followRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/admin/follows")
    public String followsPage(Authentication authentication, Model model) {
        List<Follow> follows = followRepository.findAllByOrderByRequestedAtDesc();
        model.addAttribute("pageTitle", "Follows");
        model.addAttribute("activePage", "follows");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("follows", follows);
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("totalFollows", follows.size());
        model.addAttribute("mutualConnections", followRepository.countMutualDirections() / 2);
        model.addAttribute("newThisWeek", followRepository.countByRequestedAtGreaterThanEqual(LocalDateTime.now().minusDays(7)));
        return "admin/follows";
    }

    @PostMapping("/admin/follows")
    @ResponseBody
    public ResponseEntity<?> createFollow(@RequestParam Integer followerId, @RequestParam Integer followingId) {
        if (followerId.equals(followingId)) {
            return ResponseEntity.badRequest().body(Map.of("message", "A user cannot follow themselves."));
        }
        User follower = userRepository.findById(followerId).orElse(null);
        User following = userRepository.findById(followingId).orElse(null);
        if (follower == null || following == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select two valid users."));
        }
        if (followRepository.existsByFollowerUserUserIdAndFollowingUserUserId(followerId, followingId)) {
            return ResponseEntity.badRequest().body(Map.of("message", "This follow relationship already exists."));
        }
        Follow follow = new Follow();
        follow.setFollowerUser(follower);
        follow.setFollowingUser(following);
        follow.setStatus("active");
        follow.setRequestedAt(LocalDateTime.now());
        follow.setRespondedAt(LocalDateTime.now());
        return ResponseEntity.ok(toResponse(followRepository.saveAndFlush(follow)));
    }

    @PatchMapping("/admin/follows/{followId}/status")
    @ResponseBody
    public ResponseEntity<?> updateStatus(@PathVariable Integer followId, @RequestParam String status) {
        String cleanStatus = status == null ? "" : status.trim().toLowerCase();
        if (!VALID_STATUSES.contains(cleanStatus)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select a valid follow status."));
        }
        Follow follow = followRepository.findById(followId).orElse(null);
        if (follow == null) return ResponseEntity.notFound().build();
        follow.setStatus(cleanStatus);
        follow.setRespondedAt(LocalDateTime.now());
        return ResponseEntity.ok(toResponse(followRepository.saveAndFlush(follow)));
    }

    @DeleteMapping("/admin/follows/{followId}")
    @ResponseBody
    public ResponseEntity<Void> deleteFollow(@PathVariable Integer followId) {
        if (!followRepository.existsById(followId)) return ResponseEntity.notFound().build();
        followRepository.deleteById(followId);
        return ResponseEntity.noContent().build();
    }

    private Map<String, Object> toResponse(Follow follow) {
        User follower = follow.getFollowerUser();
        User following = follow.getFollowingUser();
        return Map.ofEntries(
                Map.entry("id", follow.getFollowId()), Map.entry("followerId", follower.getUserId()),
                Map.entry("followerName", safeName(follower)), Map.entry("followerEmail", safeEmail(follower)),
                Map.entry("followingId", following.getUserId()), Map.entry("followingName", safeName(following)),
                Map.entry("followingEmail", safeEmail(following)), Map.entry("status", follow.getStatus()),
                Map.entry("requestedAt", follow.getRequestedAt().toString()));
    }

    private String safeName(User user) {
        return user.getName() == null || user.getName().isBlank() ? "Unknown user" : user.getName();
    }

    private String safeEmail(User user) {
        return user.getEmail() == null ? "" : user.getEmail();
    }
}
