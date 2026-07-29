package com.nhamhealth.nhamhealth_api.config;

import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.user.entity.Role;
import com.nhamhealth.nhamhealth_api.user.entity.User;
import com.nhamhealth.nhamhealth_api.user.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.user.repository.UserRepository;

import org.springframework.security.crypto.password.PasswordEncoder;

@Component
@Profile("dev")
public class DevDataLoader implements CommandLineRunner {

    private final RoleRepository roleRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;

    public DevDataLoader(RoleRepository roleRepository, UserRepository userRepository, PasswordEncoder passwordEncoder) {
        this.roleRepository = roleRepository;
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        Role adminRole = roleRepository.findByRoleNameIgnoreCase("ADMIN")
                .orElseGet(() -> {
                    Role r = new Role();
                    r.setRoleName("ADMIN");
                    r.setDescription("Administrator");
                    return roleRepository.save(r);
                });

        String adminEmail = "admin@example.com";
        if (userRepository.findByEmailIgnoreCase(adminEmail).isEmpty()) {
            User u = new User();
            u.setEmail(adminEmail);
            u.setRole(adminRole);
            u.setPasswordHash(passwordEncoder.encode("Admin123!"));
            u.setStatus("ACTIVE");
            u.setIsVerified(true);
            userRepository.save(u);
        }
    }
}
