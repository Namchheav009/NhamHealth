package com.nhamhealth.nhamhealth_api.service.user;

import java.time.LocalDate;
import java.time.Period;
import java.util.List;
import java.util.Locale;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.ProfileDashboardResponse;
import com.nhamhealth.nhamhealth_api.dto.response.ProfileDashboardResponse.Progress;
import com.nhamhealth.nhamhealth_api.entity.DailyNutrientTotal;
import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyNutrientTotalRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.WellnessProfileRepository;

@Service
public class ProfileDashboardService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final WellnessProfileRepository wellnessProfileRepository;
    private final DailyWellnessSummaryRepository summaryRepository;
    private final DailyNutrientTotalRepository nutrientTotalRepository;

    public ProfileDashboardService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            WellnessProfileRepository wellnessProfileRepository,
            DailyWellnessSummaryRepository summaryRepository,
            DailyNutrientTotalRepository nutrientTotalRepository) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.wellnessProfileRepository = wellnessProfileRepository;
        this.summaryRepository = summaryRepository;
        this.nutrientTotalRepository = nutrientTotalRepository;
    }

    @Transactional(readOnly = true)
    public ProfileDashboardResponse load(Integer userId) {
        return load(userId, LocalDate.now());
    }

    @Transactional(readOnly = true)
    public ProfileDashboardResponse load(Integer userId, LocalDate summaryDate) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found"));
        UserProfile identity = userProfileRepository.findByUser_UserId(userId).orElse(null);
        WellnessProfile wellness = wellnessProfileRepository.findByUser_UserId(userId).orElse(null);
        DailyWellnessSummary summary = summaryRepository
                .findByUser_UserIdAndSummaryDate(userId, summaryDate)
                .orElse(null);

        List<DailyNutrientTotal> totals = summary == null
                ? List.of()
                : nutrientTotalRepository.findByDailyWellnessSummaryDailySummaryId(summary.getDailySummaryId());

        Progress calories = progress(totals, "calorie");
        Progress protein = progress(totals, "protein");

        return new ProfileDashboardResponse(
                userId,
                user.getEmail() == null ? "" : user.getEmail(),
                identity == null ? null : identity.getFullName(),
                identity == null ? null : identity.getProfileImageUrl(),
                identity == null ? null : identity.getMembershipType(),
                identity == null ? user.getPhoneNumber() : identity.getPhoneNumber(),
                identity != null && Boolean.TRUE.equals(identity.getIsPhoneVerified()),
                identity == null ? null : identity.getDateOfBirth(),
                identity == null ? null : identity.getGender(),
                resolveAge(identity, wellness),
                wellness == null ? null : wellness.getHeightCm(),
                wellness == null ? null : wellness.getWeightKg(),
                calories,
                protein,
                progress(totals, "carbohydrate"),
                progress(totals, "fat"),
                progress(totals, "water"),
                progress(totals, "fiber"),
                progress(totals, "sugar"),
                summary == null ? null : summary.getAiInsightText());
    }

    private Progress progress(List<DailyNutrientTotal> totals, String nutrientName) {
        if (totals == null || totals.isEmpty()) {
            return null;
        }
        return totals.stream()
                .filter(total -> matches(total, nutrientName))
                .findFirst()
                .map(total -> new Progress(total.getConsumedAmount(), total.getGoalAmount()))
                .orElse(null);
    }

    private boolean matches(DailyNutrientTotal total, String expected) {
        if (total.getNutrient() == null || total.getNutrient().getNutrientName() == null) {
            return false;
        }
        return total.getNutrient().getNutrientName().toLowerCase(Locale.ROOT).contains(expected);
    }

    private Integer resolveAge(UserProfile identity, WellnessProfile wellness) {
        if (identity != null && identity.getDateOfBirth() != null) {
            return Math.max(0, Period.between(identity.getDateOfBirth(), LocalDate.now()).getYears());
        }
        return wellness == null || wellness.getAgeCached() == null
                ? null
                : wellness.getAgeCached().intValue();
    }
}
