package com.nhamhealth.nhamhealth_api.service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.Period;
import java.util.Comparator;
import java.util.Locale;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.request.AdminWellnessProfileRequest;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.WellnessProfileRepository;

@Service
public class AdminWellnessProfileService {

    private final WellnessProfileRepository wellnessProfileRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserRepository userRepository;

    public AdminWellnessProfileService(
            WellnessProfileRepository wellnessProfileRepository,
            UserProfileRepository userProfileRepository,
            UserRepository userRepository) {
        this.wellnessProfileRepository = wellnessProfileRepository;
        this.userProfileRepository = userProfileRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public WellnessPageData loadProfiles() {
        Map<Integer, UserProfile> userProfiles = userProfileRepository.findAll().stream()
                .filter(profile -> profile.getUser() != null && profile.getUser().getUserId() != null)
                .collect(Collectors.toMap(profile -> profile.getUser().getUserId(), Function.identity(), (left, right) -> left));

        var profiles = wellnessProfileRepository.findAll().stream()
                .sorted(Comparator.comparing(WellnessProfile::getUpdatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .map(profile -> toRow(profile, userProfiles.get(profile.getUser().getUserId())))
                .toList();
        long completeProfiles = profiles.stream().filter(WellnessRow::complete).count();
        return new WellnessPageData(profiles, profiles.size(), completeProfiles, profiles.size() - completeProfiles);
    }

    @Transactional
    public WellnessRow saveProfile(AdminWellnessProfileRequest request) {
        String email = request.userEmail().trim().toLowerCase(Locale.ROOT);
        User user = userRepository.findByEmailIgnoreCase(email)
                .orElseThrow(() -> new IllegalArgumentException("No user account exists for this email"));
        WellnessProfile profile = wellnessProfileRepository.findByUser_UserId(user.getUserId())
                .orElseGet(() -> {
                    WellnessProfile created = new WellnessProfile();
                    created.setUser(user);
                    created.setCreatedAt(LocalDateTime.now());
                    return created;
                });
        profile.setHeightCm(request.heightCm());
        profile.setWeightKg(request.weightKg());
        profile.setActivityLevel(request.activityLevel().trim().toUpperCase(Locale.ROOT));
        profile.setUpdatedAt(LocalDateTime.now());
        profile = wellnessProfileRepository.save(profile);

        UserProfile userProfile = userProfileRepository.findByUser_UserId(user.getUserId())
                .orElseGet(() -> createProfileFor(user));
        if (request.dateOfBirth() != null) {
            userProfile.setDateOfBirth(request.dateOfBirth());
            profile.setAgeCached(ageFrom(userProfile.getDateOfBirth()));
        }
        userProfile.setGender(normalizeGender(request.gender()));
        userProfile.setProfileImageUrl(normalizeImageUrl(request.profileImageUrl()));
        userProfile.setUpdatedAt(LocalDateTime.now());
        userProfileRepository.save(userProfile);
        return toRow(profile, userProfile);
    }

    @Transactional
    public void deleteProfile(Integer wellnessProfileId) {
        WellnessProfile profile = wellnessProfileRepository.findById(wellnessProfileId)
                .orElseThrow(() -> new IllegalArgumentException("Wellness profile was not found"));
        wellnessProfileRepository.delete(profile);
    }

    private UserProfile createProfileFor(User user) {
        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName(defaultName(user.getEmail()));
        profile.setCreatedAt(now);
        profile.setUpdatedAt(now);
        return profile;
    }

    private WellnessRow toRow(WellnessProfile wellness, UserProfile identity) {
        User user = wellness.getUser();
        String name = identity != null && identity.getFullName() != null && !identity.getFullName().isBlank()
                ? identity.getFullName()
                : user.getEmail();
        Short age = resolveAge(identity, wellness);
        boolean complete = wellness.getHeightCm() != null
                && wellness.getWeightKg() != null
                && wellness.getActivityLevel() != null
                && !wellness.getActivityLevel().isBlank();
        return new WellnessRow(
                wellness.getWellnessProfileId(),
                initials(name),
                name,
                user.getEmail(),
                identity != null ? identity.getProfileImageUrl() : null,
                identity != null ? identity.getGender() : null,
                identity != null ? identity.getDateOfBirth() : null,
                age,
                wellness.getHeightCm(),
                wellness.getWeightKg(),
                bmi(wellness.getHeightCm(), wellness.getWeightKg()),
                wellness.getActivityLevel(),
                complete,
                wellness.getUpdatedAt());
    }

    private BigDecimal bmi(BigDecimal heightCm, BigDecimal weightKg) {
        if (heightCm == null || weightKg == null || heightCm.signum() <= 0) {
            return null;
        }
        BigDecimal heightMetres = heightCm.divide(BigDecimal.valueOf(100), 4, RoundingMode.HALF_UP);
        return weightKg.divide(heightMetres.multiply(heightMetres), 1, RoundingMode.HALF_UP);
    }

    private Short resolveAge(UserProfile identity, WellnessProfile wellness) {
        if (identity != null && identity.getDateOfBirth() != null) {
            return ageFrom(identity.getDateOfBirth());
        }
        return wellness.getAgeCached();
    }

    private Short ageFrom(LocalDate dateOfBirth) {
        int years = Period.between(dateOfBirth, LocalDate.now()).getYears();
        return (short) Math.max(years, 0);
    }

    private String initials(String name) {
        if (name == null || name.isBlank()) {
            return "NA";
        }
        String[] words = name.trim().split("\\s+");
        if (words.length == 1) {
            return words[0].substring(0, Math.min(2, words[0].length())).toUpperCase(Locale.ROOT);
        }
        return (words[0].substring(0, 1) + words[words.length - 1].substring(0, 1)).toUpperCase(Locale.ROOT);
    }

    private String defaultName(String email) {
        if (email == null || email.isBlank()) {
            return "Nham Health user";
        }
        int at = email.indexOf('@');
        return at > 0 ? email.substring(0, at) : email;
    }

    private String normalizeImageUrl(String imageUrl) {
        return imageUrl == null || imageUrl.isBlank() ? null : imageUrl.trim();
    }

    private String normalizeGender(String gender) {
        return gender == null || gender.isBlank() ? null : gender.trim();
    }

    public record WellnessPageData(java.util.List<WellnessRow> profiles, long totalProfiles, long completeProfiles, long incompleteProfiles) {
    }

    public record WellnessRow(
            Integer id,
            String initials,
            String name,
            String email,
            String profileImageUrl,
            String gender,
            LocalDate dateOfBirth,
            Short age,
            BigDecimal heightCm,
            BigDecimal weightKg,
            BigDecimal bmi,
            String activityLevel,
            boolean complete,
            LocalDateTime updatedAt) {
    }
}
