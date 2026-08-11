package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class ProfileImageStorageServiceTests {

    private static final String SUPABASE_URL = "https://example-project.supabase.co";
    private static final String BUCKET = "nhamhealth-images";

    private final ProfileImageStorageService storageService = new ProfileImageStorageService(
            "uploads", SUPABASE_URL, "sb_secret_test", BUCKET);

    @Test
    void acceptsLocalAndConfiguredSupabaseMealImageUrls() {
        assertTrue(storageService.isStoredMealImageUrl("/uploads/meal-images/local-image.png"));
        assertTrue(storageService.isStoredMealImageUrl(
                SUPABASE_URL + "/storage/v1/object/public/" + BUCKET + "/meal-images/shared-image.png"));
        assertFalse(storageService.isStoredMealImageUrl(
                "https://untrusted.example/meal-images/shared-image.png"));
    }

    @Test
    void acceptsOnlyTheMatchingRecipeStepStorageFolder() {
        assertTrue(storageService.isStoredRecipeStepImageUrl(
                SUPABASE_URL + "/storage/v1/object/public/" + BUCKET + "/recipe-step-images/shared-step.png"));
        assertFalse(storageService.isStoredRecipeStepImageUrl(
                SUPABASE_URL + "/storage/v1/object/public/" + BUCKET + "/meal-images/shared-image.png"));
    }
}
