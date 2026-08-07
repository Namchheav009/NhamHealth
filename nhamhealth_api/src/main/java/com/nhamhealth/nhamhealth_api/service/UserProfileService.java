package com.nhamhealth.nhamhealth_api.service;

import java.time.LocalDateTime;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.ProfileImageResponse;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Service
public class UserProfileService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;

    public UserProfileService(UserRepository userRepository, UserProfileRepository userProfileRepository) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
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
}
