package com.nhamhealth.nhamhealth_api.config;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

import java.util.Optional;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.auth.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

class SupabaseAdminBootstrapTest {
    private final RoleRepository roles = mock(RoleRepository.class);
    private final UserRepository users = mock(UserRepository.class);
    private final BCryptPasswordEncoder encoder = new BCryptPasswordEncoder();

    @Test
    void createsVerifiedAdminWithEncodedPassword() {
        when(roles.save(any(Role.class))).thenAnswer(call -> call.getArgument(0));
        new SupabaseAdminBootstrap(roles, users, encoder, " admin@example.com ", "Test123!").run();
        var captured = ArgumentCaptor.forClass(User.class);
        verify(users).save(captured.capture());
        User admin = captured.getValue();
        assertEquals("admin@example.com", admin.getEmail());
        assertEquals("ADMIN", admin.getRole().getRoleName());
        assertEquals("ACTIVE", admin.getStatus());
        assertTrue(admin.getIsVerified());
        assertTrue(encoder.matches("Test123!", admin.getPasswordHash()));
    }

    @Test
    void leavesExistingAccountUntouched() {
        when(users.findByEmailIgnoreCase("admin@example.com")).thenReturn(Optional.of(new User()));
        new SupabaseAdminBootstrap(roles, users, encoder, "admin@example.com", "Test123!").run();
        verify(users, never()).save(any());
        verifyNoInteractions(roles);
    }

    @Test
    void rejectsMissingCredentials() {
        assertThrows(IllegalStateException.class,
                () -> new SupabaseAdminBootstrap(roles, users, encoder, "", "").run());
        verifyNoInteractions(users, roles);
    }
}
