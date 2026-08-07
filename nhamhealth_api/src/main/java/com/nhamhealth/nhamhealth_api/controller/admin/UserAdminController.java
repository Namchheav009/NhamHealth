package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.Map;

import jakarta.validation.Valid;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.multipart.MultipartFile;

import com.nhamhealth.nhamhealth_api.dto.request.AdminCreateUserRequest;
import com.nhamhealth.nhamhealth_api.dto.request.AdminWellnessProfileRequest;
import com.nhamhealth.nhamhealth_api.dto.request.AdminUpdateUserRequest;
import com.nhamhealth.nhamhealth_api.service.AdminUserService;
import com.nhamhealth.nhamhealth_api.service.AdminUserService.UserPageData;
import com.nhamhealth.nhamhealth_api.service.AdminWellnessProfileService;
import com.nhamhealth.nhamhealth_api.service.AdminWellnessProfileService.WellnessPageData;
import com.nhamhealth.nhamhealth_api.service.ProfileImageStorageService;

@Controller
public class UserAdminController {

    private final AdminUserService adminUserService;
    private final AdminWellnessProfileService adminWellnessProfileService;
    private final ProfileImageStorageService profileImageStorageService;

    public UserAdminController(AdminUserService adminUserService,
            AdminWellnessProfileService adminWellnessProfileService,
            ProfileImageStorageService profileImageStorageService) {
        this.adminUserService = adminUserService;
        this.adminWellnessProfileService = adminWellnessProfileService;
        this.profileImageStorageService = profileImageStorageService;
    }

    @GetMapping("/admin/users")
    public String users(Authentication authentication, Model model) {
        UserPageData users = adminUserService.loadUsers();

        model.addAttribute("pageTitle", "Users");
        model.addAttribute("userPage", users);
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "Admin");
        return "admin/users";
    }

    @PostMapping("/admin/users")
    @ResponseBody
    public ResponseEntity<?> createUser(@Valid @RequestBody AdminCreateUserRequest request) {
        try {
            return ResponseEntity.status(HttpStatus.CREATED).body(adminUserService.createUser(request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT).body(Map.of("message", exception.getMessage()));
        }
    }

    @PutMapping("/admin/users/{userId}")
    @ResponseBody
    public ResponseEntity<?> updateUser(
            @PathVariable Integer userId,
            @Valid @RequestBody AdminUpdateUserRequest request,
            Authentication authentication) {
        try {
            return ResponseEntity.ok(adminUserService.updateUser(userId, request, authentication.getName()));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @DeleteMapping("/admin/users/{userId}")
    @ResponseBody
    public ResponseEntity<?> deleteUser(@PathVariable Integer userId, Authentication authentication) {
        try {
            adminUserService.deleteUser(userId, authentication.getName());
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }

    @PostMapping(value = "/admin/profile-images", consumes = "multipart/form-data")
    @ResponseBody
    public ResponseEntity<?> uploadProfileImage(@RequestParam("file") MultipartFile file) {
        try {
            return ResponseEntity.ok(Map.of("profileImageUrl", profileImageStorageService.storeProfileImage(file)));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        } catch (IllegalStateException exception) {
            return ResponseEntity.internalServerError().body(Map.of("message", exception.getMessage()));
        }
    }

    @GetMapping("/admin/wellness-profiles")
    public String wellnessProfiles(Authentication authentication, Model model) {
        WellnessPageData profiles = adminWellnessProfileService.loadProfiles();

        model.addAttribute("pageTitle", "Wellness Profiles");
        model.addAttribute("activePage", "wellness-profiles");
        model.addAttribute("wellnessPage", profiles);
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "Admin");
        return "admin/wellness-profiles";
    }

    @PostMapping("/admin/wellness-profiles")
    @ResponseBody
    public ResponseEntity<?> saveWellnessProfile(@Valid @RequestBody AdminWellnessProfileRequest request) {
        try {
            return ResponseEntity.ok(adminWellnessProfileService.saveProfile(request));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", exception.getMessage()));
        }
    }

    @DeleteMapping("/admin/wellness-profiles/{wellnessProfileId}")
    @ResponseBody
    public ResponseEntity<?> deleteWellnessProfile(@PathVariable Integer wellnessProfileId) {
        try {
            adminWellnessProfileService.deleteProfile(wellnessProfileId);
            return ResponseEntity.noContent().build();
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of("message", exception.getMessage()));
        }
    }
}
