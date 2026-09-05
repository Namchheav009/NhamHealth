package com.nhamhealth.nhamhealth_api.service.user;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.dto.request.ProfileUpdateRequest;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.WellnessProfileRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

class UserProfileServiceTests {

    private UserRepository userRepository;
    private UserProfileRepository userProfileRepository;
    private WellnessProfileRepository wellnessProfileRepository;
    private PlasgateSmsService smsService;
    private UserProfileService service;

    @BeforeEach
    void setUp() {
        currentProfile = null;
        userRepository = mock(UserRepository.class);
        userProfileRepository = mock(UserProfileRepository.class);
        wellnessProfileRepository = mock(WellnessProfileRepository.class);
        smsService = mock(PlasgateSmsService.class);
        service = new UserProfileService(
                userRepository,
                userProfileRepository,
                wellnessProfileRepository,
                smsService);

        when(wellnessProfileRepository.findByUser_UserId(1)).thenReturn(Optional.empty());
        when(smsService.normalizePhoneNumber("012345678")).thenReturn("85512345678");
        when(smsService.normalizePhoneNumber("85512345678")).thenReturn("85512345678");
        when(smsService.normalizePhoneNumber("098765432")).thenReturn("85598765432");
    }

    @Test
    void phoneOnlyProfileCanBeSavedWithoutAnEmail() {
        User user = mockUser("85512345678");
        UserProfile profile = profile(user, "85512345678", true);
        when(userRepository.findByPhoneNumber("85512345678")).thenReturn(Optional.of(user));
        when(userProfileRepository.findFirstByPhoneNumber("85512345678")).thenReturn(Optional.of(profile));
        when(userProfileRepository.findFirstByPhoneNumber("012345678")).thenReturn(Optional.of(profile));

        service.updateProfile(1, request("Phone User", "", "012345678"));

        verify(user).setEmail(null);
        verify(user).setPhoneNumber("85512345678");
        assertThat(profile.getPhoneNumber()).isEqualTo("85512345678");
        assertThat(profile.getIsPhoneVerified()).isTrue();
    }

    @Test
    void changingThePhoneRequiresVerificationBeforeProfileSave() {
        User user = mockUser("85512345678");
        when(user.getEmail()).thenReturn("user@example.com");
        UserProfile profile = profile(user, "85512345678", true);
        when(userRepository.findByPhoneNumber("85598765432")).thenReturn(Optional.empty());
        when(userProfileRepository.findFirstByPhoneNumber("85598765432")).thenReturn(Optional.empty());
        when(userProfileRepository.findFirstByPhoneNumber("098765432")).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.updateProfile(
                1, request("Phone User", "user@example.com", "098765432")))
                .isInstanceOf(IllegalArgumentException.class)
                .hasMessage("Verify the new phone number before saving your profile");
        assertThat(profile.getPhoneNumber()).isEqualTo("85512345678");
        assertThat(profile.getIsPhoneVerified()).isTrue();
        verify(user, never()).setPhoneNumber(any());
    }

    @Test
    void emailOnlyProfileCanBeSavedWithoutAPhone() {
        User user = mockUser(null);
        when(user.getEmail()).thenReturn("new@example.com");
        UserProfile profile = profile(user, null, false);
        when(userRepository.findByEmailIgnoreCase("new@example.com")).thenReturn(Optional.of(user));

        service.updateProfile(1, request("Email User", " NEW@Example.com ", ""));

        verify(user).setEmail("new@example.com");
        verify(user).setPhoneNumber(null);
        assertThat(profile.getPhoneNumber()).isNull();
    }

    private User mockUser(String phone) {
        User user = mock(User.class);
        when(user.getUserId()).thenReturn(1);
        when(user.getPhoneNumber()).thenReturn(phone);
        when(userRepository.findById(1)).thenReturn(Optional.of(user));
        when(userProfileRepository.findByUser_UserId(1))
                .thenAnswer(invocation -> Optional.ofNullable(currentProfile));
        return user;
    }

    private UserProfile currentProfile;

    private UserProfile profile(User user, String phone, boolean verified) {
        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName("Original User");
        profile.setPhoneNumber(phone);
        profile.setIsPhoneVerified(verified);
        currentProfile = profile;
        return profile;
    }

    private ProfileUpdateRequest request(String fullName, String email, String phone) {
        return new ProfileUpdateRequest(
                fullName,
                email,
                phone,
                null,
                null,
                null,
                null);
    }
}
