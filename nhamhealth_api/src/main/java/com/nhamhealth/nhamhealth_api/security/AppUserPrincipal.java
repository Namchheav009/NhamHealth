package com.nhamhealth.nhamhealth_api.security;

import java.util.Collection;
import java.util.List;
import java.util.Locale;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import com.nhamhealth.nhamhealth_api.entity.User;

public final class AppUserPrincipal implements UserDetails {

    private final Integer userId;
    private final String email;
    private final String passwordHash;
    private final String role;
    private final boolean enabled;

    private AppUserPrincipal(
            Integer userId,
            String email,
            String passwordHash,
            String role,
            boolean enabled) {
        this.userId = userId;
        this.email = email;
        this.passwordHash = passwordHash;
        this.role = role;
        this.enabled = enabled;
    }

    public static AppUserPrincipal from(User user) {
        String role = normalizeRole(user.getRole().getRoleName());
        boolean active = "ACTIVE".equalsIgnoreCase(user.getStatus());
        boolean verified = Boolean.TRUE.equals(user.getIsVerified());
        String username = user.getEmail();
        if (username == null || username.isBlank()) {
            username = user.getPhoneNumber() != null ? user.getPhoneNumber() : String.valueOf(user.getUserId());
        }

        return new AppUserPrincipal(
                user.getUserId(),
                username,
                user.getPasswordHash(),
                role,
                active && verified);
    }

    private static String normalizeRole(String roleName) {
        String normalized = roleName.toUpperCase(Locale.ROOT);
        return normalized.startsWith("ROLE_") ? normalized.substring(5) : normalized;
    }

    public Integer userId() {
        return userId;
    }

    public String role() {
        return role;
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return List.of(new SimpleGrantedAuthority("ROLE_" + role));
    }

    @Override
    public String getPassword() {
        return passwordHash;
    }

    @Override
    public String getUsername() {
        return email;
    }

    @Override
    public boolean isEnabled() {
        return enabled;
    }
}
