package com.nhamhealth.nhamhealth_api.controller.auth;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.response.AuthErrorResponse;
import com.nhamhealth.nhamhealth_api.dto.response.AuthenticatedUserResponse;
import com.nhamhealth.nhamhealth_api.dto.request.LoginRequest;
import com.nhamhealth.nhamhealth_api.dto.request.GoogleLoginRequest;
import com.nhamhealth.nhamhealth_api.dto.request.RegisterRequest;
import com.nhamhealth.nhamhealth_api.dto.request.ForgotPasswordRequest;
import com.nhamhealth.nhamhealth_api.dto.request.ResetPasswordRequest;
import com.nhamhealth.nhamhealth_api.dto.request.VerifyPasswordResetCodeRequest;
import com.nhamhealth.nhamhealth_api.dto.request.ChangePasswordRequest;
import com.nhamhealth.nhamhealth_api.dto.request.VerifyRegistrationRequest;
import com.nhamhealth.nhamhealth_api.dto.response.MessageResponse;
import com.nhamhealth.nhamhealth_api.dto.response.PasswordResetVerificationResponse;
import com.nhamhealth.nhamhealth_api.exception.MobileLoginNotAllowedException;
import com.nhamhealth.nhamhealth_api.service.AuthService;
import com.nhamhealth.nhamhealth_api.service.PasswordResetService;
import com.nhamhealth.nhamhealth_api.service.RegistrationVerificationService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;
    private final RegistrationVerificationService registrationVerificationService;

    public AuthController(AuthService authService, PasswordResetService passwordResetService,
            RegistrationVerificationService registrationVerificationService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
        this.registrationVerificationService = registrationVerificationService;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        try {
            return ResponseEntity.ok(authService.loginMobileUser(request));
        } catch (MobileLoginNotAllowedException exception) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new AuthErrorResponse(exception.getMessage()));
        } catch (AuthenticationException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthErrorResponse("Invalid email or password"));
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            registrationVerificationService.register(request);
            return ResponseEntity.status(HttpStatus.ACCEPTED)
                    .body(new MessageResponse("Verification code sent to your email"));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.CONFLICT)
                    .body(new AuthErrorResponse(exception.getMessage()));
        }
    }

    @PostMapping("/google")
    public ResponseEntity<?> google(@Valid @RequestBody GoogleLoginRequest request) {
        try {
            return ResponseEntity.ok(authService.loginWithGoogle(request.idToken()));
        } catch (MobileLoginNotAllowedException exception) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new AuthErrorResponse(exception.getMessage()));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthErrorResponse(exception.getMessage()));
        } catch (IllegalStateException exception) {
            return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                    .body(new AuthErrorResponse(exception.getMessage()));
        }
    }

    @GetMapping("/me")
    public AuthenticatedUserResponse me(@AuthenticationPrincipal Jwt jwt) {
        Number userId = jwt.getClaim("userId");
        List<String> roles = jwt.getClaimAsStringList("roles");
        String role = roles == null || roles.isEmpty() ? "USER" : roles.getFirst();
        return authService.authenticatedUser(
                userId.intValue(), jwt.getSubject(), role);
    }

    @PostMapping("/forgot-password")
    public ResponseEntity<MessageResponse> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request) {
        passwordResetService.sendCode(request.email());
        return ResponseEntity.accepted().body(new MessageResponse(
                "If an account exists for this email, a verification code has been sent"));
    }

    @PostMapping("/verify-reset-code")
    public PasswordResetVerificationResponse verifyResetCode(
            @Valid @RequestBody VerifyPasswordResetCodeRequest request) {
        return passwordResetService.verifyCode(request.email(), request.code());
    }

    @PostMapping("/reset-password")
    public MessageResponse resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.resetPassword(request.resetToken(), request.newPassword());
        return new MessageResponse("Password reset successfully");
    }

    @PostMapping("/verify-registration")
    public ResponseEntity<?> verifyRegistration(@Valid @RequestBody VerifyRegistrationRequest request) {
        return ResponseEntity.ok(registrationVerificationService.verify(request.email(), request.code()));
    }

    @PostMapping("/resend-registration-code")
    public ResponseEntity<MessageResponse> resendRegistrationCode(
            @Valid @RequestBody ForgotPasswordRequest request) {
        registrationVerificationService.resend(request.email());
        return ResponseEntity.accepted().body(new MessageResponse("A new verification code was sent"));
    }

    @PostMapping("/change-password")
    public ResponseEntity<?> changePassword(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody ChangePasswordRequest request) {
        try {
            Number userId = jwt.getClaim("userId");
            authService.changePassword(userId.intValue(), request);
            return ResponseEntity.ok(new MessageResponse("Password changed successfully"));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(new AuthErrorResponse(exception.getMessage()));
        }
    }
}
