package com.nhamhealth.nhamhealth_api.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.test.context.TestPropertySource;
import org.springframework.security.crypto.password.PasswordEncoder;

import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.ReportReasonRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@SpringBootTest
@TestPropertySource(properties = {
        "app.seed.admin-email=seed-admin@example.com",
        "app.seed.admin-password=SeedAdmin123!",
        "app.seed.user-email=seed-user@example.com",
        "app.seed.user-password=SeedUser123!"
})
class DevDataLoaderTest {

    @Autowired
    private DevDataLoader devDataLoader;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private ReportReasonRepository reportReasonRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private AuthenticationManager authenticationManager;

    @Test
    void shouldSeedAdminAndUserRolesAndUsers() throws Exception {
        devDataLoader.run();

        Role adminRole = roleRepository.findByRoleNameIgnoreCase("ADMIN").orElseThrow();
        Role userRole = roleRepository.findByRoleNameIgnoreCase("USER").orElseThrow();
        assertEquals("ADMIN", adminRole.getRoleName());
        assertEquals("USER", userRole.getRoleName());

        User adminUser = userRepository.findByEmailIgnoreCase("seed-admin@example.com").orElseThrow();
        User regularUser = userRepository.findByEmailIgnoreCase("seed-user@example.com").orElseThrow();

        assertNotNull(adminUser.getPasswordHash());
        assertNotNull(regularUser.getPasswordHash());
        assertTrue(adminUser.getRole().getRoleName().equalsIgnoreCase("ADMIN"));
        assertTrue(regularUser.getRole().getRoleName().equalsIgnoreCase("USER"));
        assertTrue(passwordEncoder.matches("SeedAdmin123!", adminUser.getPasswordHash()));
        assertTrue(adminUser.getIsVerified());
        assertEquals("ACTIVE", adminUser.getStatus());
        assertEquals(
                java.util.List.of("Spam", "Harassment", "False information", "Inappropriate content"),
                reportReasonRepository.findAllByIsActiveTrueOrderByReportReasonIdAsc().stream()
                        .map(reason -> reason.getReasonName())
                        .toList());

        var authentication = authenticationManager.authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated(
                        "seed-admin@example.com", "SeedAdmin123!"));
        assertTrue(authentication.isAuthenticated());
        assertTrue(authentication.getAuthorities().stream()
                .anyMatch(authority -> "ROLE_ADMIN".equals(authority.getAuthority())));
    }
}
