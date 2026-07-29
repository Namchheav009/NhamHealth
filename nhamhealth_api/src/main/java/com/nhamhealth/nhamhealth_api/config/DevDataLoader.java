package com.nhamhealth.nhamhealth_api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.user.entity.Role;
import com.nhamhealth.nhamhealth_api.user.entity.User;
import com.nhamhealth.nhamhealth_api.user.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.user.repository.UserRepository;

@Component
public class DevDataLoader implements CommandLineRunner {

    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final String adminEmail;
    private final String adminPassword;
    private final String userEmail;
    private final String userPassword;

    public DevDataLoader(
            RoleRepository roleRepository,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            @Value("${APP_ADMIN_EMAIL:admin@nhamhealth.local}") String adminEmail,
            @Value("${APP_ADMIN_PASSWORD:Admin123!}") String adminPassword,
            @Value("${APP_USER_EMAIL:user@nhamhealth.local}") String userEmail,
            @Value("${APP_USER_PASSWORD:User123!}") String userPassword) {
        this.roleRepository = roleRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.adminEmail = adminEmail;
        this.adminPassword = adminPassword;
        this.userEmail = userEmail;
        this.userPassword = userPassword;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        Role adminRole = getOrCreateRole("ADMIN", "Administrator");
        Role userRole = getOrCreateRole("USER", "Standard User");

        seedUser(adminEmail, adminPassword, adminRole);
        seedUser(userEmail, userPassword, userRole);
    }

    private Role getOrCreateRole(String roleName, String description) {
        return roleRepository.findByRoleNameIgnoreCase(roleName)
                .orElseGet(() -> {
                    Role role = new Role();
                    role.setRoleName(roleName);
                    role.setDescription(description);
                    return roleRepository.save(role);
                });
    }

    private void seedUser(String email, String password, Role role) {
        if (userRepository.findByEmailIgnoreCase(email).isEmpty()) {
            User user = new User();
            user.setEmail(email);
            user.setRole(role);
            user.setPasswordHash(passwordEncoder.encode(password));
            user.setStatus("ACTIVE");
            user.setIsVerified(true);
            userRepository.save(user);
        }
    }
}
