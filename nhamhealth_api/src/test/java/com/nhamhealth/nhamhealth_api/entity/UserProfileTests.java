package com.nhamhealth.nhamhealth_api.entity;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.time.LocalDateTime;

import org.junit.jupiter.api.Test;

class UserProfileTests {

    @Test
    void initializesRequiredTimestampsBeforeInsert() {
        UserProfile profile = new UserProfile();

        profile.onCreate();

        assertNotNull(profile.getCreatedAt());
        assertNotNull(profile.getUpdatedAt());
        assertEquals(profile.getCreatedAt(), profile.getUpdatedAt());
    }

    @Test
    void preservesAnExplicitCreationTimestampBeforeInsert() {
        UserProfile profile = new UserProfile();
        LocalDateTime createdAt = LocalDateTime.of(2026, 1, 2, 3, 4);
        profile.setCreatedAt(createdAt);

        profile.onCreate();

        assertEquals(createdAt, profile.getCreatedAt());
        assertNotNull(profile.getUpdatedAt());
    }

    @Test
    void refreshesUpdatedTimestampBeforeUpdate() {
        UserProfile profile = new UserProfile();
        LocalDateTime previousUpdate = LocalDateTime.of(2026, 1, 2, 3, 4);
        profile.setUpdatedAt(previousUpdate);

        profile.onUpdate();

        assertTrue(profile.getUpdatedAt().isAfter(previousUpdate));
    }
}
