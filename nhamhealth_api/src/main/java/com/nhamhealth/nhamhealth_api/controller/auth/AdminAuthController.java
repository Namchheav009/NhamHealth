package com.nhamhealth.nhamhealth_api.controller.auth;

import com.nhamhealth.nhamhealth_api.dto.request.LoginRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AuthErrorResponse;
import com.nhamhealth.nhamhealth_api.dto.response.LoginChallengeResponse;
import com.nhamhealth.nhamhealth_api.service.auth.AuthService;
import com.nhamhealth.nhamhealth_api.service.auth.LoginAttemptService;
import com.nhamhealth.nhamhealth_api.service.auth.RegistrationVerificationService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.AuthenticationException;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/admin/auth")
public class AdminAuthController {
    private final AuthService auth;
    private final LoginAttemptService attempts;
    private final RegistrationVerificationService verification;

    public AdminAuthController(AuthService auth, LoginAttemptService attempts,
            RegistrationVerificationService verification) {
        this.auth = auth;
        this.attempts = attempts;
        this.verification = verification;
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        attempts.checkAllowed(request.email());
        try {
            var result = auth.loginAdmin(request);
            attempts.recordSuccess(request.email());
            if (result.otpRequired()) {
                var destination = verification.sendLoginCode(result.otpUser(), request.email(), true);
                return ResponseEntity.accepted().body(new LoginChallengeResponse(true, destination.value(),
                        "Verify the code using POST /api/v1/auth/verify-login to receive your access token"));
            }
            return ResponseEntity.ok(result.response());
        } catch (AuthenticationException | IllegalArgumentException exception) {
            attempts.recordFailure(request.email());
            return ResponseEntity.status(401).body(new AuthErrorResponse("Invalid admin email or password"));
        }
    }
}
