package com.nhamhealth.nhamhealth_api.controller.api;

import java.time.LocalDate;

import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.nhamhealth.nhamhealth_api.dto.request.DailyNutritionUpdateRequest;
import com.nhamhealth.nhamhealth_api.dto.request.SendEmailCodeRequest;
import com.nhamhealth.nhamhealth_api.dto.request.ProfileUpdateRequest;
import com.nhamhealth.nhamhealth_api.dto.request.SendPhoneCodeRequest;
import com.nhamhealth.nhamhealth_api.dto.request.VerifyEmailCodeRequest;
import com.nhamhealth.nhamhealth_api.dto.request.VerifyPhoneCodeRequest;
import com.nhamhealth.nhamhealth_api.exception.PasswordResetException;
import com.nhamhealth.nhamhealth_api.service.auth.EmailChangeVerificationService;
import com.nhamhealth.nhamhealth_api.service.auth.PhoneVerificationService;
import com.nhamhealth.nhamhealth_api.service.user.ProfileDashboardService;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;
import com.nhamhealth.nhamhealth_api.service.user.UserProfileService;
import com.nhamhealth.nhamhealth_api.service.wellness.DailyNutritionService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/users")
public class UserApiController {

    private final UserProfileService userProfileService;
    private final ProfileImageStorageService profileImageStorageService;
    private final ProfileDashboardService profileDashboardService;
    private final DailyNutritionService dailyNutritionService;
    private final PhoneVerificationService phoneVerificationService;
    private final EmailChangeVerificationService emailChangeVerificationService;

    public UserApiController(
            UserProfileService userProfileService,
            ProfileImageStorageService profileImageStorageService,
            ProfileDashboardService profileDashboardService,
            DailyNutritionService dailyNutritionService,
            PhoneVerificationService phoneVerificationService,
            EmailChangeVerificationService emailChangeVerificationService) {
        this.userProfileService = userProfileService;
        this.profileImageStorageService = profileImageStorageService;
        this.profileDashboardService = profileDashboardService;
        this.dailyNutritionService = dailyNutritionService;
        this.phoneVerificationService = phoneVerificationService;
        this.emailChangeVerificationService = emailChangeVerificationService;
    }

    @PostMapping("/me/daily-wellness/nutrients")
    public ResponseEntity<?> addDailyNutrition(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody DailyNutritionUpdateRequest request) {
        Number userId = jwt.getClaim("userId");
        dailyNutritionService.add(userId.intValue(), request);
        LocalDate date = request.date() == null ? LocalDate.now() : request.date();
        return ResponseEntity.ok(profileDashboardService.load(userId.intValue(), date));
    }

    @GetMapping("/me/dashboard")
    public ResponseEntity<?> profileDashboard(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        Number userId = jwt.getClaim("userId");
        return ResponseEntity.ok(profileDashboardService.load(
                userId.intValue(), date == null ? LocalDate.now() : date));
    }

    @PutMapping("/me/profile")
    public ResponseEntity<?> updateProfile(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody ProfileUpdateRequest request) {
        try {
            Number userId = jwt.getClaim("userId");
            userProfileService.updateProfile(userId.intValue(), request);
            return ResponseEntity.ok(profileDashboardService.load(userId.intValue()));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", exception.getMessage()));
        }
    }

    @PutMapping(value = "/me/profile-image", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> uploadProfileImage(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam("file") MultipartFile file) {
        try {
            Number userId = jwt.getClaim("userId");
            String imageUrl = profileImageStorageService.storeProfileImage(file);
            return ResponseEntity.ok(userProfileService.updateProfileImage(userId.intValue(), imageUrl));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(java.util.Map.of("message", exception.getMessage()));
        } catch (IllegalStateException exception) {
            return ResponseEntity.internalServerError().body(java.util.Map.of("message", exception.getMessage()));
        }
    }

    @DeleteMapping("/me/profile-image")
    public ResponseEntity<?> deleteProfileImage(@AuthenticationPrincipal Jwt jwt) {
        Number userId = jwt.getClaim("userId");
        userProfileService.updateProfileImage(userId.intValue(), null);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/me/phone/send-code")
    public ResponseEntity<?> sendPhoneVerificationCode(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody SendPhoneCodeRequest request) {
        Number userId = jwt.getClaim("userId");
        return ResponseEntity.ok(phoneVerificationService.sendVerificationCode(userId.intValue(), request.phone()));
    }

    @PostMapping("/me/email/send-code")
    public ResponseEntity<?> sendEmailVerificationCode(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody SendEmailCodeRequest request) {
        Number userId = jwt.getClaim("userId");
        return ResponseEntity.ok(emailChangeVerificationService.sendVerificationCode(
                userId.intValue(), request.email()));
    }

    @PostMapping("/me/email/verify-code")
    public ResponseEntity<?> verifyEmailCode(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody VerifyEmailCodeRequest request) {
        Number userId = jwt.getClaim("userId");
        return ResponseEntity.ok(emailChangeVerificationService.verifyCode(
                userId.intValue(), request.email(), request.code()));
    }

    @PostMapping("/me/phone/verify-code")
    public ResponseEntity<?> verifyPhoneCode(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody VerifyPhoneCodeRequest request) {
        Number userId = jwt.getClaim("userId");
        return ResponseEntity.ok(phoneVerificationService.verifyCode(userId.intValue(), request.phone(), request.code()));
    }

    @ExceptionHandler(PasswordResetException.class)
    public ResponseEntity<?> handlePasswordResetException(PasswordResetException exception) {
        return ResponseEntity.status(exception.getStatus())
                .body(java.util.Map.of("message", exception.getMessage()));
    }

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<?> handleIllegalArgumentException(IllegalArgumentException exception) {
        return ResponseEntity.badRequest()
                .body(java.util.Map.of("message", exception.getMessage()));
    }
}
