package com.nhamhealth.nhamhealth_api.service.user;

import java.time.LocalDateTime;
import java.time.Period;
import java.util.Locale;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.ProfileImageResponse;
import com.nhamhealth.nhamhealth_api.dto.request.ProfileUpdateRequest;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.WellnessProfileRepository;
import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;

@Service
public class UserProfileService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final WellnessProfileRepository wellnessProfileRepository;

    public UserProfileService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            WellnessProfileRepository wellnessProfileRepository) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.wellnessProfileRepository = wellnessProfileRepository;
    }

    @Transactional
    public void updateProfile(Integer userId, ProfileUpdateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        userRepository.findByEmailIgnoreCase(email)
                .filter(existing -> !existing.getUserId().equals(userId))
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("That email address is already in use");
                });

        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = userProfileRepository.findByUser_UserId(userId)
                .orElseGet(() -> createProfile(user, now));
        user.setEmail(email);
        profile.setFullName(request.fullName().trim());
        profile.setPhoneNumber(normalize(request.phone()));
        profile.setDateOfBirth(request.dateOfBirth());
        profile.setGender(normalize(request.gender()));
        profile.setUpdatedAt(now);
        userRepository.save(user);
        userProfileRepository.save(profile);

        WellnessProfile wellness = wellnessProfileRepository.findByUser_UserId(userId)
                .orElseGet(() -> {
                    WellnessProfile created = new WellnessProfile();
                    created.setUser(user);
                    created.setCreatedAt(now);
                    created.setActivityLevel("MODERATE");
                    return created;
                });
        wellness.setHeightCm(request.heightCm());
        wellness.setWeightKg(request.weightKg());
        if (request.dateOfBirth() != null) {
            wellness.setAgeCached((short) Math.max(
                    0,
                    Period.between(request.dateOfBirth(), java.time.LocalDate.now()).getYears()));
        }
        wellness.setUpdatedAt(now);
        wellnessProfileRepository.save(wellness);
    }

    @Transactional
    public ProfileImageResponse updateProfileImage(Integer userId, String imageUrl) {
        User user = userRepository.findById(userId).orElseThrow();
        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = userProfileRepository.findByUser_UserId(userId)
                .orElseGet(() -> createProfile(user, now));
        profile.setProfileImageUrl(normalizeImageUrl(imageUrl));
        profile.setUpdatedAt(now);
        userProfileRepository.save(profile);
        return new ProfileImageResponse(profile.getProfileImageUrl());
    }

    private UserProfile createProfile(User user, LocalDateTime now) {
        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName(defaultName(user.getEmail()));
        profile.setCreatedAt(now);
        profile.setUpdatedAt(now);
        return profile;
    }

    private String defaultName(String email) {
        int at = email == null ? -1 : email.indexOf('@');
        return at > 0 ? email.substring(0, at) : "Nham Health user";
    }

    private String normalizeImageUrl(String imageUrl) {
        return imageUrl == null || imageUrl.isBlank() ? null : imageUrl.trim();
    }

    private String normalize(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
