package com.nhamhealth.nhamhealth_api.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.TestPropertySource;

import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@SpringBootTest
@TestPropertySource(properties = {
        "APP_ADMIN_EMAIL=seed-admin@example.com",
        "APP_ADMIN_PASSWORD=SeedAdmin123!",
        "APP_USER_EMAIL=seed-user@example.com",
        "APP_USER_PASSWORD=SeedUser123!"
})
class DevDataLoaderTest {

    @Autowired
    private DevDataLoader devDataLoader;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

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
    }
}
