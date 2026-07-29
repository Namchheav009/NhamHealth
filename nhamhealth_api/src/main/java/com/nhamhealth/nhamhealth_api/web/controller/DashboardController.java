package com.nhamhealth.nhamhealth_api.web.controller;

import java.util.List;
import java.util.stream.Collectors;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.user.entity.User;
import com.nhamhealth.nhamhealth_api.user.repository.UserRepository;

@Controller
public class DashboardController {

    private final UserRepository userRepository;

    public DashboardController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/")
    public String home() {
        return "redirect:/dashboard";
    }

    @GetMapping("/dashboard")
    public String dashboard(Authentication authentication, Model model) {
        long totalUsers = userRepository.count();

        List<User> recentUsers = userRepository.findAll().stream()
                .sorted((left, right) -> right.getCreatedAt() == null ? 0
                        : right.getCreatedAt().compareTo(left.getCreatedAt() == null ? null : left.getCreatedAt()))
                .limit(5)
                .collect(Collectors.toList());

        model.addAttribute("email", authentication.getName());
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("pageTitle", "Dashboard");
        model.addAttribute("totalUsers", totalUsers);
        model.addAttribute("recentUsers", recentUsers);
        return "admin/dashboard";
    }

    @GetMapping("/admin/dashboard")
    public String adminDashboard(Authentication authentication, Model model) {
        return dashboard(authentication, model);
    }
}
