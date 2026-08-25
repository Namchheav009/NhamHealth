package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import java.math.BigDecimal;
import java.util.Optional;

import org.junit.jupiter.api.Test;

import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;
import com.nhamhealth.nhamhealth_api.repository.WellnessProfileRepository;

class AiUserHealthProfileServiceTests {

    @Test
    void loadsAgeHeightAndWeightThroughTheUsersWellnessProfile() {
        WellnessProfileRepository repository = mock(WellnessProfileRepository.class);
        WellnessProfile profile = new WellnessProfile();
        profile.setAgeCached((short) 29);
        profile.setHeightCm(BigDecimal.valueOf(172));
        profile.setWeightKg(BigDecimal.valueOf(68));
        profile.setActivityLevel(" moderate ");
        when(repository.findByUser_UserId(7)).thenReturn(Optional.of(profile));

        var result = new AiUserHealthProfileService(repository).load(7);

        assertEquals(7, result.userId());
        assertEquals((short) 29, result.age());
        assertEquals(BigDecimal.valueOf(172), result.heightCm());
        assertEquals(BigDecimal.valueOf(68), result.weightKg());
        assertEquals(new BigDecimal("23.0"), result.bmi());
        assertEquals("moderate", result.activityLevel());
        assertTrue(result.hasAgeHeightAndWeight());
        verify(repository).findByUser_UserId(7);
    }
}
