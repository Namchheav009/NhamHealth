package com.nhamhealth.nhamhealth_api.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.auth.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

@Component
@Profile("supabase")
@ConditionalOnProperty(name = "app.seed.admin-enabled", havingValue = "true")
public class SupabaseAdminBootstrap implements CommandLineRunner {
    private final RoleRepository roles;
    private final UserRepository users;
    private final PasswordEncoder encoder;
    private final String email;
    private final String password;

    public SupabaseAdminBootstrap(RoleRepository roles, UserRepository users, PasswordEncoder encoder,
            @Value("${app.seed.admin-email:}") String email,
            @Value("${app.seed.admin-password:}") String password) {
        this.roles = roles;
        this.users = users;
        this.encoder = encoder;
        this.email = email.trim();
        this.password = password;
    }

    @Override
    @Transactional
    public void run(String... args) {
        if (email.isBlank() || password.isBlank()) {
            throw new IllegalStateException("Admin bootstrap requires app.seed.admin-email and app.seed.admin-password");
        }
        // Never reset a password or elevate an existing account during startup.
        if (users.findByEmailIgnoreCase(email).isPresent()) {
            return;
        }
        Role role = roles.findByRoleNameIgnoreCase("ADMIN").orElseGet(() -> {
            Role admin = new Role();
            admin.setRoleName("ADMIN");
            admin.setDescription("Administrator");
            return roles.save(admin);
        });
        User admin = new User();
        admin.setEmail(email);
        admin.setPasswordHash(encoder.encode(password));
        admin.setRole(role);
        admin.setStatus("ACTIVE");
        admin.setIsVerified(true);
        users.save(admin);
    }
}
