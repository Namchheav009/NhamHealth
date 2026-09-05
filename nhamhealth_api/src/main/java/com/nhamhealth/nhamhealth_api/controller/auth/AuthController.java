package com.nhamhealth.nhamhealth_api.controller.auth;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.AuthenticationException;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.dto.request.AppPinRequest;
import com.nhamhealth.nhamhealth_api.dto.request.ChangePasswordRequest;
import com.nhamhealth.nhamhealth_api.dto.request.ForgotPasswordRequest;
import com.nhamhealth.nhamhealth_api.dto.request.GoogleLoginRequest;
import com.nhamhealth.nhamhealth_api.dto.request.LoginRequest;
import com.nhamhealth.nhamhealth_api.dto.request.RefreshTokenRequest;
import com.nhamhealth.nhamhealth_api.dto.request.RegisterRequest;
import com.nhamhealth.nhamhealth_api.dto.request.ResetPasswordRequest;
import com.nhamhealth.nhamhealth_api.dto.request.VerifyPasswordResetCodeRequest;
import com.nhamhealth.nhamhealth_api.dto.request.VerifyRegistrationRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AuthErrorResponse;
import com.nhamhealth.nhamhealth_api.dto.response.AuthenticatedUserResponse;
import com.nhamhealth.nhamhealth_api.dto.response.LoginChallengeResponse;
import com.nhamhealth.nhamhealth_api.dto.response.MessageResponse;
import com.nhamhealth.nhamhealth_api.dto.response.PasswordResetVerificationResponse;
import com.nhamhealth.nhamhealth_api.dto.response.PinVerificationResponse;
import com.nhamhealth.nhamhealth_api.exception.MobileLoginNotAllowedException;
import com.nhamhealth.nhamhealth_api.service.auth.AuthService;
import com.nhamhealth.nhamhealth_api.service.auth.LoginAttemptService;
import com.nhamhealth.nhamhealth_api.service.auth.PasswordResetService;
import com.nhamhealth.nhamhealth_api.service.auth.RegistrationVerificationService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/auth")
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;
    private final RegistrationVerificationService registrationVerificationService;
    private final LoginAttemptService loginAttemptService;

    public AuthController(AuthService authService, PasswordResetService passwordResetService,
            RegistrationVerificationService registrationVerificationService,
            LoginAttemptService loginAttemptService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
        this.registrationVerificationService = registrationVerificationService;
        this.loginAttemptService = loginAttemptService;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        loginAttemptService.checkAllowed(request.email());
        try {
            var result = authService.loginMobileUser(request);
            loginAttemptService.recordSuccess(request.email());
            if (result.otpRequired()) {
                var destination = registrationVerificationService.sendLoginCode(
                        result.otpUser(), request.email(), true);
                boolean isPhone = "SMS".equals(destination.deliveryMethod());
                return ResponseEntity.status(HttpStatus.ACCEPTED).body(
                        new LoginChallengeResponse(true, destination.value(),
                                "A login verification code was sent to your " + (isPhone ? "phone" : "email")));
            }
            return ResponseEntity.ok(result.response());
        } catch (MobileLoginNotAllowedException exception) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN)
                    .body(new AuthErrorResponse(exception.getMessage()));
        } catch (AuthenticationException exception) {
            loginAttemptService.recordFailure(request.email());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthErrorResponse("Invalid email, phone number, or password"));
        } catch (IllegalArgumentException exception) {
            loginAttemptService.recordFailure(request.email());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body(new AuthErrorResponse("Invalid email, phone number, or password"));
        }
    }

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            registrationVerificationService.register(request);
            boolean isPhone = !request.email().contains("@") && request.email().matches(".*\\d+.*");
            return ResponseEntity.status(HttpStatus.ACCEPTED)
                    .body(new MessageResponse("Verification code sent to your " + (isPhone ? "phone" : "email")));
        } catch (IllegalArgumentException exception) {
            HttpStatus status = exception.getMessage() != null
                    && exception.getMessage().startsWith("An account with")
                            ? HttpStatus.CONFLICT
                            : HttpStatus.BAD_REQUEST;
            return ResponseEntity.status(status)
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

    @PostMapping("/refresh")
    public ResponseEntity<?> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return ResponseEntity.ok(authService.refresh(request.refreshToken()));
    }

    @PostMapping("/logout")
    public MessageResponse logout(@Valid @RequestBody RefreshTokenRequest request) {
        authService.logout(request.refreshToken());
        return new MessageResponse("Signed out successfully");
    }

    @PostMapping("/logout-all")
    public MessageResponse logoutAll(@AuthenticationPrincipal Jwt jwt) {
        Number userId = jwt.getClaim("userId");
        authService.logoutAll(userId.intValue());
        return new MessageResponse("Signed out on all devices");
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
                "If an account exists, a verification code has been sent"));
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

    @PostMapping("/verify-login")
    public ResponseEntity<?> verifyLogin(@Valid @RequestBody VerifyRegistrationRequest request) {
        return ResponseEntity.ok(registrationVerificationService.verifyLogin(request.email(), request.code()));
    }

    @PostMapping("/resend-login-code")
    public ResponseEntity<MessageResponse> resendLoginCode(
            @Valid @RequestBody ForgotPasswordRequest request) {
        registrationVerificationService.resendLoginCode(request.email());
        return ResponseEntity.accepted().body(new MessageResponse("A new login verification code was sent"));
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

    @PostMapping("/pin")
    public MessageResponse setPin(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AppPinRequest request) {
        Number userId = jwt.getClaim("userId");
        authService.setAppPin(userId.intValue(), request.pin());
        return new MessageResponse("App PIN saved securely");
    }

    @PostMapping("/pin/verify")
    public PinVerificationResponse verifyPin(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AppPinRequest request) {
        Number userId = jwt.getClaim("userId");
        return new PinVerificationResponse(
                authService.verifyAppPin(userId.intValue(), request.pin()));
    }

    @PostMapping("/pin/disable")
    public MessageResponse disablePin(@AuthenticationPrincipal Jwt jwt) {
        Number userId = jwt.getClaim("userId");
        authService.disableAppPin(userId.intValue());
        return new MessageResponse("App PIN disabled");
    }
}
