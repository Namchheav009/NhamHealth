package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;

import static org.assertj.core.api.Assertions.assertThat;
import static org.hamcrest.Matchers.containsString;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.test.web.servlet.MockMvc;

import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.auth.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.admin.AdminDashboardService;
import com.nhamhealth.nhamhealth_api.service.admin.AdminDashboardService.DashboardSnapshot;
import com.nhamhealth.nhamhealth_api.service.admin.AdminUserService;

@SpringBootTest
@AutoConfigureMockMvc
class UserAdminControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private AdminDashboardService adminDashboardService;

    @Autowired
    private AdminUserService adminUserService;

    private Role userRole;

    @BeforeEach
    void setUp() {
        userRole = roleRepository.findByRoleNameIgnoreCase("USER")
                .orElseGet(() -> {
                    Role r = new Role();
                    r.setRoleName("USER");
                    r.setDescription("Standard user");
                    return roleRepository.save(r);
                });
    }

    @Test
    void authenticatedAdminCanDeleteUserAndUserIsExcludedFromDashboard() throws Exception {
        User target = new User();
        target.setEmail("testdeleteuser@example.com");
        target.setRole(userRole);
        target.setStatus("ACTIVE");
        target.setIsVerified(true);
        target.setPasswordHash("$2a$10$dummyhashfortestonly12345678901234567890123456789012");
        target = userRepository.saveAndFlush(target);

        UserProfile profile = new UserProfile();
        profile.setUser(target);
        profile.setFullName("Test Delete User");
        profile.setCreatedAt(LocalDateTime.now());
        profile.setUpdatedAt(LocalDateTime.now());
        userProfileRepository.saveAndFlush(profile);

        Integer targetUserId = target.getUserId();

        try {
            // Delete user via controller
            mockMvc.perform(delete("/admin/users/{userId}", targetUserId)
                    .with(user("admin@nhamhealth.local").roles("ADMIN"))
                    .with(csrf()))
                    .andExpect(status().isNoContent());

            // DB status is DELETED
            User updated = userRepository.findById(targetUserId).orElseThrow();
            assertThat(updated.getStatus()).isEqualTo("DELETED");
            assertThat(updated.getIsVerified()).isFalse();

            // Excluded from admin users list
            boolean inUserList = adminUserService.loadUsers().users().stream()
                    .anyMatch(u -> u.id().equals(targetUserId));
            assertThat(inUserList).isFalse();

            // Excluded from dashboard newest users table
            DashboardSnapshot snapshot = adminDashboardService.loadDashboard();
            boolean inDashboardTable = snapshot.recentUsers().stream()
                    .anyMatch(u -> targetUserId.equals(u.id()));
            assertThat(inDashboardTable).isFalse();

        } finally {
            userProfileRepository.findByUser_UserId(targetUserId)
                    .ifPresent(userProfileRepository::delete);
            userRepository.findById(targetUserId)
                    .ifPresent(userRepository::delete);
        }
    }

    @Test
    void cannotDeleteOwnAdminAccount() throws Exception {
        mockMvc.perform(delete("/admin/users/{userId}", 999999)
                .with(user("admin@nhamhealth.local").roles("ADMIN"))
                .with(csrf()))
                .andExpect(status().isBadRequest())
                .andExpect(content().string(containsString("User account was not found")));
    }

    @Test
    void authenticatedAdminCanDeletePhoneOnlyUserWithoutError() throws Exception {
        User phoneUser = new User();
        phoneUser.setPhoneNumber("+85512999888");
        phoneUser.setEmail(null);
        phoneUser.setRole(userRole);
        phoneUser.setStatus("ACTIVE");
        phoneUser.setIsVerified(true);
        phoneUser.setPasswordHash("$2a$10$dummyhashfortestonly12345678901234567890123456789012");
        phoneUser = userRepository.saveAndFlush(phoneUser);

        UserProfile profile = new UserProfile();
        profile.setUser(phoneUser);
        profile.setFullName("Phone User");
        profile.setCreatedAt(LocalDateTime.now());
        profile.setUpdatedAt(LocalDateTime.now());
        userProfileRepository.saveAndFlush(profile);

        Integer phoneUserId = phoneUser.getUserId();

        try {
            mockMvc.perform(delete("/admin/users/{userId}", phoneUserId)
                    .with(user("admin@nhamhealth.local").roles("ADMIN"))
                    .with(csrf()))
                    .andExpect(status().isNoContent());

            User updated = userRepository.findById(phoneUserId).orElseThrow();
            assertThat(updated.getStatus()).isEqualTo("DELETED");

            boolean inUserList = adminUserService.loadUsers().users().stream()
                    .anyMatch(u -> u.id().equals(phoneUserId));
            assertThat(inUserList).isFalse();

            DashboardSnapshot snapshot = adminDashboardService.loadDashboard();
            boolean inDashboardTable = snapshot.recentUsers().stream()
                    .anyMatch(u -> phoneUserId.equals(u.id()));
            assertThat(inDashboardTable).isFalse();
        } finally {
            userProfileRepository.findByUser_UserId(phoneUserId)
                    .ifPresent(userProfileRepository::delete);
            userRepository.findById(phoneUserId)
                    .ifPresent(userRepository::delete);
        }
    }

    @Test
    void dashboardPageContainsCsrfAndTableActions() throws Exception {
        mockMvc.perform(get("/dashboard")
                .with(user("admin@nhamhealth.local").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/dashboard"))
                .andExpect(content().string(containsString("name=\"_csrf\"")))
                .andExpect(content().string(containsString("class=\"actions-column\"")))
                .andExpect(content().string(containsString("delete-user")));
    }
}
