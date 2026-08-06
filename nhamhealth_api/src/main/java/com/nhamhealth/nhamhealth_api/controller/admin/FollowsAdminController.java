package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;

import com.nhamhealth.nhamhealth_api.entity.Follow;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class FollowsAdminController {

    private final FollowRepository followRepository;
    private final UserRepository userRepository;

    public FollowsAdminController(FollowRepository followRepository, UserRepository userRepository) {
        this.followRepository = followRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/admin/follows")
    public String followsPage(Authentication authentication, Model model) {
        List<Follow> follows = followRepository.findAll();
        model.addAttribute("pageTitle", "Follows");
        model.addAttribute("activePage", "follows");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("follows", follows);
        model.addAttribute("totalFollows", follows.size());
        return "admin/follows";
    }

    @PostMapping("/admin/follows")
    public String createFollow(@org.springframework.web.bind.annotation.RequestParam String followerEmail,
            @org.springframework.web.bind.annotation.RequestParam String followingEmail) {
        java.util.Optional<User> followerOpt = userRepository.findByEmailIgnoreCase(followerEmail);
        java.util.Optional<User> followingOpt = userRepository.findByEmailIgnoreCase(followingEmail);
        if (followerOpt.isPresent() && followingOpt.isPresent()) {
            Follow f = new Follow();
            f.setFollowerUser(followerOpt.get());
            f.setFollowingUser(followingOpt.get());
            f.setStatus("active");
            f.setRequestedAt(java.time.LocalDateTime.now());
            followRepository.save(f);
        }
        return "redirect:/admin/follows";
    }
}
