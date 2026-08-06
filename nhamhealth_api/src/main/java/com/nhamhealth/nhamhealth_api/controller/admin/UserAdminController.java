package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.WellnessProfileRepository;

@Controller
public class UserAdminController {

    private final UserRepository userRepository;
    private final WellnessProfileRepository wellnessProfileRepository;

    public UserAdminController(UserRepository userRepository,
            WellnessProfileRepository wellnessProfileRepository) {
        this.userRepository = userRepository;
        this.wellnessProfileRepository = wellnessProfileRepository;
    }

    @GetMapping("/admin/users")
    public String users(Authentication authentication, Model model) {
        List<User> users = userRepository.findAll().stream()
                .sorted(Comparator.comparing((User user) -> user.getCreatedAt(),
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .collect(Collectors.toList());

        List<User> recentUsers = users.stream()
                .limit(5)
                .collect(Collectors.toList());

        long totalUsers = userRepository.count();
        long verifiedUsers = userRepository.countByIsVerifiedTrue();

        model.addAttribute("pageTitle", "Users");
        model.addAttribute("users", users);
        model.addAttribute("recentUsers", recentUsers);
        model.addAttribute("totalUsers", totalUsers);
        model.addAttribute("verifiedUsers", verifiedUsers);
        model.addAttribute("adminName", authentication.getName());
        return "admin/users";
    }

    @GetMapping("/admin/wellness-profiles")
    public String wellnessProfiles(Authentication authentication, Model model) {
        var profiles = wellnessProfileRepository.findAll();

        model.addAttribute("pageTitle", "Wellness Profiles");
        model.addAttribute("activePage", "wellness-profiles");
        model.addAttribute("wellnessProfiles", profiles);
        model.addAttribute("adminName", authentication.getName());
        return "admin/wellness-profiles";
    }
}
