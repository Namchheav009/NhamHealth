package com.nhamhealth.nhamhealth_api.auth;

import java.time.LocalDateTime;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import com.jayway.jsonpath.JsonPath;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@SpringBootTest
@AutoConfigureMockMvc
class AuthenticationFlowTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @BeforeEach
    void createTestAccounts() {
        Role adminRole = findOrCreateRole("ADMIN");
        Role userRole = findOrCreateRole("USER");
        createUserIfMissing("admin@nhamhealth.local", "Admin123!", adminRole);
        createUserIfMissing("user@nhamhealth.local", "User123!", userRole);
    }

    @Test
    void mobileUserReceivesBearerTokenAndCanReadProfile() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"user@nhamhealth.local","password":"User123!"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresIn").value(86400))
                .andExpect(jsonPath("$.user.email").value("user@nhamhealth.local"))
                .andExpect(jsonPath("$.user.role").value("USER"))
                .andReturn();

        String accessToken = JsonPath.read(
                result.getResponse().getContentAsString(), "$.accessToken");
        mockMvc.perform(get("/api/v1/auth/me")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("user@nhamhealth.local"))
                .andExpect(jsonPath("$.role").value("USER"));
    }

    @Test
    void invalidMobileCredentialsReturnUnauthorized() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"user@nhamhealth.local","password":"wrong"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
    }

    @Test
    void adminAccountIsDirectedToTheWebsiteInsteadOfMobileLogin() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"admin@nhamhealth.local","password":"Admin123!"}
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminCanUseFormLoginAndOpenDashboard() throws Exception {
        mockMvc.perform(post("/login")
                        .with(csrf())
                        .param("email", "admin@nhamhealth.local")
                        .param("password", "Admin123!"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/dashboard"));

        mockMvc.perform(get("/dashboard").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/dashboard"));
    }

    @Test
    void regularUserCannotUseAdminFormLogin() throws Exception {
        mockMvc.perform(post("/login")
                        .with(csrf())
                        .param("email", "user@nhamhealth.local")
                        .param("password", "User123!"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/login?error=not-admin"));
    }

    private Role findOrCreateRole(String roleName) {
        return roleRepository.findByRoleNameIgnoreCase(roleName).orElseGet(() -> {
            Role role = new Role();
            role.setRoleName(roleName);
            return roleRepository.save(role);
        });
    }

    private void createUserIfMissing(String email, String password, Role role) {
        if (userRepository.findByEmailIgnoreCase(email).isPresent()) {
            return;
        }

        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setRole(role);
        user.setStatus("ACTIVE");
        user.setIsVerified(true);
        user.setVerifiedAt(LocalDateTime.now());
        userRepository.save(user);
    }
}
