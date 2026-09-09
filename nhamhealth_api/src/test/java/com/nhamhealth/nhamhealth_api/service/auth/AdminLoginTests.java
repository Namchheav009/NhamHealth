package com.nhamhealth.nhamhealth_api.service.auth;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.*;
import java.util.*;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.*;
import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.security.AppUserPrincipal;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.dto.request.LoginRequest;

class AdminLoginTests {
    @Test void rejectsUserRoleBeforeIssuingTokens() {
        AuthenticationManager manager = mock(AuthenticationManager.class);
        UserRepository users = mock(UserRepository.class);
        AppUserPrincipal principal = mock(AppUserPrincipal.class);
        when(principal.role()).thenReturn("USER");
        when(manager.authenticate(any())).thenReturn(new UsernamePasswordAuthenticationToken(principal, null, List.of()));
        AuthService service = new AuthService(manager, users, null, null, null, null, null, null, null, null, null);
        assertThrows(BadCredentialsException.class, () -> service.loginAdmin(new LoginRequest("user@example.com", "test")));
        verifyNoInteractions(users);
    }
    @Test void adminOtpRequirementIsPreserved() {
        AuthenticationManager manager = mock(AuthenticationManager.class);
        UserRepository users = mock(UserRepository.class);
        AppUserPrincipal principal = mock(AppUserPrincipal.class);
        when(principal.role()).thenReturn("ADMIN");
        when(principal.userId()).thenReturn(7);
        when(manager.authenticate(any())).thenReturn(new UsernamePasswordAuthenticationToken(principal, null, List.of()));
        User user = new User();
        user.setLoginOtpRequired(true);
        when(users.findById(7)).thenReturn(Optional.of(user));
        AuthService service = new AuthService(manager, users, null, null, null, null, null, null, null, null, null);
        var result = service.loginAdmin(new LoginRequest("admin@example.com", "test"));
        assertTrue(result.otpRequired());
        assertNull(result.response());
    }
}
