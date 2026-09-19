package com.nhamhealth.nhamhealth_api.auth;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import java.time.LocalDateTime;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.auth.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.auth.GoogleTokenVerifier;
import com.nhamhealth.nhamhealth_api.service.auth.LoginAttemptService;
import org.springframework.mail.javamail.JavaMailSender;

@SpringBootTest
@AutoConfigureMockMvc
class AuthEnvironmentAndStatusTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private LoginAttemptService loginAttemptService;

    @MockitoBean
    private GoogleTokenVerifier googleTokenVerifier;

    @MockitoBean
    private JavaMailSender mailSender;

    private Role userRole;
    private Role adminRole;

    @BeforeEach
    void setUp() {
        loginAttemptService.reset();
        userRole = roleRepository.findByRoleNameIgnoreCase("USER").orElseGet(() -> {
            Role r = new Role();
            r.setRoleName("USER");
            r.setDescription("Standard User");
            return roleRepository.save(r);
        });

        adminRole = roleRepository.findByRoleNameIgnoreCase("ADMIN").orElseGet(() -> {
            Role r = new Role();
            r.setRoleName("ADMIN");
            r.setDescription("Administrator");
            return roleRepository.save(r);
        });
    }

    @Test
    void verifiedUser_canLoginViaMobileApi() throws Exception {
        String email = "verified-mobile-user@example.com";
        createOrUpdateUser(email, "Password123!", userRole, "ACTIVE", true);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"Password123!"}
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.accessToken").isNotEmpty())
                .andExpect(jsonPath("$.user.role").value("USER"));
    }

    @Test
    void invalidPassword_returns401Unauthorized() throws Exception {
        String email = "verified-mobile-user-invalid@example.com";
        createOrUpdateUser(email, "CorrectPass123!", userRole, "ACTIVE", true);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"WrongPassword!"}
                                """.formatted(email)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email, phone number, or password"));
    }

    @Test
    void unverifiedPendingAccount_returns403WithClearMessage() throws Exception {
        String email = "unverified-mobile-user@example.com";
        createOrUpdateUser(email, "Password123!", userRole, "PENDING", false);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"Password123!"}
                                """.formatted(email)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("Account is not verified. Please verify your email or phone number before signing in."));
    }

    @Test
    void adminUser_forbiddenFromMobileEndpoint() throws Exception {
        String email = "admin-portal-only@example.com";
        createOrUpdateUser(email, "AdminPassword123!", adminRole, "ACTIVE", true);

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"%s","password":"AdminPassword123!"}
                                """.formatted(email)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.message").value("This account must sign in through the administration portal"));
    }

    private void createOrUpdateUser(String email, String password, Role role, String status, boolean isVerified) {
        User user = userRepository.findByEmailIgnoreCase(email).orElseGet(User::new);
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setRole(role);
        user.setStatus(status);
        user.setIsVerified(isVerified);
        if (isVerified) {
            user.setVerifiedAt(LocalDateTime.now());
        }
        userRepository.save(user);
    }
}

