package com.nhamhealth.nhamhealth_api.config;

import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.ReportReason;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.ReportReasonRepository;
import com.nhamhealth.nhamhealth_api.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Component
public class DevDataLoader implements CommandLineRunner {

    private final RoleRepository roleRepository;
    private final ReportReasonRepository reportReasonRepository;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final String adminEmail;
    private final String adminPassword;
    private final String userEmail;
    private final String userPassword;

    public DevDataLoader(
            RoleRepository roleRepository,
            ReportReasonRepository reportReasonRepository,
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            @Value("${app.seed.admin-email}") String adminEmail,
            @Value("${app.seed.admin-password}") String adminPassword,
            @Value("${app.seed.user-email}") String userEmail,
            @Value("${app.seed.user-password}") String userPassword) {
        this.roleRepository = roleRepository;
        this.reportReasonRepository = reportReasonRepository;
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
        seedReportReasons();
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
        User user = userRepository.findByEmailIgnoreCase(email)
                .orElseGet(User::new);

        user.setEmail(email.trim());
        user.setRole(role);
        user.setStatus("ACTIVE");
        user.setIsVerified(true);

        if (user.getPasswordHash() == null
                || !passwordEncoder.matches(password, user.getPasswordHash())) {
            user.setPasswordHash(passwordEncoder.encode(password));
        }

        userRepository.save(user);
    }

    private void seedReportReasons() {
        List.of("Spam", "Harassment", "False information", "Inappropriate content")
                .forEach(this::getOrCreateReportReason);
    }

    private void getOrCreateReportReason(String name) {
        if (reportReasonRepository.existsByReasonNameIgnoreCase(name)) {
            return;
        }
        ReportReason reason = new ReportReason();
        reason.setReasonName(name);
        reason.setIsActive(true);
        reportReasonRepository.save(reason);
    }
}
