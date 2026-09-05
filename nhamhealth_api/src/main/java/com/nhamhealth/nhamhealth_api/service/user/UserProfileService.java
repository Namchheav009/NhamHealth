package com.nhamhealth.nhamhealth_api.service.user;

import java.time.LocalDateTime;
import java.time.Period;
import java.util.Locale;
import java.util.Objects;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.ProfileImageResponse;
import com.nhamhealth.nhamhealth_api.dto.request.ProfileUpdateRequest;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.WellnessProfileRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;
import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;

@Service
public class UserProfileService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final WellnessProfileRepository wellnessProfileRepository;
    private final PlasgateSmsService smsService;

    public UserProfileService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            WellnessProfileRepository wellnessProfileRepository,
            PlasgateSmsService smsService) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.wellnessProfileRepository = wellnessProfileRepository;
        this.smsService = smsService;
    }

    @Transactional
    public void updateProfile(Integer userId, ProfileUpdateRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        String email = normalizeEmail(request.email());
        String rawPhone = normalize(request.phone());
        String phone = rawPhone == null ? null : smsService.normalizePhoneNumber(rawPhone);

        if (email == null && phone == null) {
            throw new IllegalArgumentException("Add an email address or phone number before saving");
        }
        if (email != null) {
            userRepository.findByEmailIgnoreCase(email)
                    .filter(existing -> !existing.getUserId().equals(userId))
                    .ifPresent(existing -> {
                        throw new IllegalArgumentException("That email address is already in use");
                    });
        }
        if (phone != null) {
            ensurePhoneAvailable(userId, rawPhone, phone);
        }

        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = userProfileRepository.findByUser_UserId(userId)
                .orElseGet(() -> createProfile(user, now));

        String activeEmail = normalizeEmail(user.getEmail());
        if (email != null && !Objects.equals(email, activeEmail)) {
            throw new IllegalArgumentException("Verify the new email address before saving your profile");
        }
        String savedProfilePhone = normalizeExistingPhone(profile.getPhoneNumber());
        if (phone != null && !Objects.equals(phone, savedProfilePhone)) {
            throw new IllegalArgumentException("Verify the new phone number before saving your profile");
        }

        boolean phoneRemainsVerified = phone != null
                && Boolean.TRUE.equals(profile.getIsPhoneVerified())
                && Objects.equals(phone, normalizeExistingPhone(profile.getPhoneNumber()));
        String activePhone = normalizeExistingPhone(user.getPhoneNumber());
        if (email == null && !phoneRemainsVerified && activePhone == null) {
            throw new IllegalArgumentException("Verify your phone number before removing your email address");
        }

        user.setEmail(email);
        profile.setFullName(request.fullName().trim());
        profile.setPhoneNumber(phone);
        profile.setIsPhoneVerified(phoneRemainsVerified);
        if (!phoneRemainsVerified) {
            profile.setPhoneVerifiedAt(null);
        }
        if (phone == null) {
            user.setPhoneNumber(null);
        } else if (phoneRemainsVerified) {
            user.setPhoneNumber(phone);
        } else if (Objects.equals(activePhone, phone)) {
            // A phone is not a sign-in identifier until this profile has
            // successfully completed phone verification.
            user.setPhoneNumber(null);
        }
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

    private String normalizeEmail(String email) {
        return email == null || email.isBlank()
                ? null
                : email.trim().toLowerCase(Locale.ROOT);
    }

    private String normalizeExistingPhone(String phone) {
        if (phone == null || phone.isBlank()) {
            return null;
        }
        try {
            return smsService.normalizePhoneNumber(phone);
        } catch (IllegalArgumentException exception) {
            return null;
        }
    }

    private void ensurePhoneAvailable(Integer userId, String rawPhone, String phone) {
        userRepository.findByPhoneNumber(phone)
                .filter(existing -> !existing.getUserId().equals(userId))
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("That phone number is already in use");
                });
        ensureProfilePhoneAvailable(userId, phone);
        if (!phone.equals(rawPhone)) {
            ensureProfilePhoneAvailable(userId, rawPhone);
        }
    }

    private void ensureProfilePhoneAvailable(Integer userId, String phone) {
        userProfileRepository.findFirstByPhoneNumber(phone)
                .filter(existing -> !existing.getUser().getUserId().equals(userId))
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("That phone number is already in use");
                });
    }

    private String normalize(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
