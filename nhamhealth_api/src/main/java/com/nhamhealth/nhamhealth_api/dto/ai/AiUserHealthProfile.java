package com.nhamhealth.nhamhealth_api.dto.ai;

import java.math.BigDecimal;
import java.math.RoundingMode;

import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;

/**
 * The authenticated user's saved wellness data supplied to AI-backed features.
 * Values remain owned by wellness_profiles and are resolved through its user_id
 * relationship instead of being copied into each AI table.
 */
public record AiUserHealthProfile(
        Integer userId,
        Short age,
        BigDecimal heightCm,
        BigDecimal weightKg,
        BigDecimal bmi,
        String activityLevel) {

    public static AiUserHealthProfile from(Integer userId, WellnessProfile profile) {
        if (profile == null) return empty(userId);
        BigDecimal height = positive(profile.getHeightCm());
        BigDecimal weight = positive(profile.getWeightKg());
        return new AiUserHealthProfile(
                userId,
                positive(profile.getAgeCached()),
                height,
                weight,
                calculateBmi(height, weight),
                normalizedActivity(profile.getActivityLevel()));
    }

    public static AiUserHealthProfile empty(Integer userId) {
        return new AiUserHealthProfile(userId, null, null, null, null, "unknown");
    }

    public boolean hasAgeHeightAndWeight() {
        return age != null && heightCm != null && weightKg != null;
    }

    private static BigDecimal calculateBmi(BigDecimal heightCm, BigDecimal weightKg) {
        if (heightCm == null || weightKg == null) return null;
        BigDecimal heightMeters = heightCm.movePointLeft(2);
        return weightKg.divide(heightMeters.multiply(heightMeters), 1, RoundingMode.HALF_UP);
    }

    private static BigDecimal positive(BigDecimal value) {
        return value != null && value.signum() > 0 ? value : null;
    }

    private static Short positive(Short value) {
        return value != null && value > 0 ? value : null;
    }

    private static String normalizedActivity(String value) {
        return value == null || value.isBlank() ? "unknown" : value.trim();
    }
}
