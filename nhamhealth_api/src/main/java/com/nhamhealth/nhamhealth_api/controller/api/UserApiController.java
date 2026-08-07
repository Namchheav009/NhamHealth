package com.nhamhealth.nhamhealth_api.controller.api;

import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.nhamhealth.nhamhealth_api.dto.response.ProfileImageResponse;
import com.nhamhealth.nhamhealth_api.service.ProfileImageStorageService;
import com.nhamhealth.nhamhealth_api.service.UserProfileService;

@RestController
@RequestMapping("/api/v1/users")
public class UserApiController {

    private final UserProfileService userProfileService;
    private final ProfileImageStorageService profileImageStorageService;

    public UserApiController(
            UserProfileService userProfileService,
            ProfileImageStorageService profileImageStorageService) {
        this.userProfileService = userProfileService;
        this.profileImageStorageService = profileImageStorageService;
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
}
