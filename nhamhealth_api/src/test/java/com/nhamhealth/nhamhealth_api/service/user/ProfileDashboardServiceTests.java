package com.nhamhealth.nhamhealth_api.service.user;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import com.nhamhealth.nhamhealth_api.dto.response.ProfileDashboardResponse;
import com.nhamhealth.nhamhealth_api.entity.DailyNutrientTotal;
import com.nhamhealth.nhamhealth_api.entity.DailyWellnessSummary;
import com.nhamhealth.nhamhealth_api.entity.Nutrient;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyNutrientTotalRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.WellnessProfileRepository;

class ProfileDashboardServiceTests {

    private UserRepository userRepository;
    private UserProfileRepository userProfileRepository;
    private WellnessProfileRepository wellnessProfileRepository;
    private DailyWellnessSummaryRepository summaryRepository;
    private DailyNutrientTotalRepository nutrientTotalRepository;
    private ProfileDashboardService service;

    @BeforeEach
    void setUp() {
        userRepository = mock(UserRepository.class);
        userProfileRepository = mock(UserProfileRepository.class);
        wellnessProfileRepository = mock(WellnessProfileRepository.class);
        summaryRepository = mock(DailyWellnessSummaryRepository.class);
        nutrientTotalRepository = mock(DailyNutrientTotalRepository.class);

        service = new ProfileDashboardService(
                userRepository,
                userProfileRepository,
                wellnessProfileRepository,
                summaryRepository,
                nutrientTotalRepository);
    }

    @Test
    void load_executesNutrientTotalQueryExactlyOnce_whenSummaryExists() {
        Integer userId = 10;
        LocalDate today = LocalDate.of(2026, 9, 26);

        User user = new User();
        ReflectionTestUtils.setField(user, "userId", userId);
        user.setEmail("user@example.com");

        UserProfile profile = new UserProfile();
        profile.setFullName("Test User");

        WellnessProfile wellness = new WellnessProfile();
        wellness.setHeightCm(new BigDecimal("170"));
        wellness.setWeightKg(new BigDecimal("65"));

        DailyWellnessSummary summary = new DailyWellnessSummary();
        ReflectionTestUtils.setField(summary, "dailySummaryId", 42);

        Nutrient calorieNutrient = new Nutrient();
        calorieNutrient.setNutrientName("Calories");
        DailyNutrientTotal calorieTotal = new DailyNutrientTotal();
        calorieTotal.setNutrient(calorieNutrient);
        calorieTotal.setConsumedAmount(new BigDecimal("1500"));
        calorieTotal.setGoalAmount(new BigDecimal("2000"));

        Nutrient proteinNutrient = new Nutrient();
        proteinNutrient.setNutrientName("Protein");
        DailyNutrientTotal proteinTotal = new DailyNutrientTotal();
        proteinTotal.setNutrient(proteinNutrient);
        proteinTotal.setConsumedAmount(new BigDecimal("80"));
        proteinTotal.setGoalAmount(new BigDecimal("120"));

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(profile));
        when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.of(wellness));
        when(summaryRepository.findByUser_UserIdAndSummaryDate(userId, today)).thenReturn(Optional.of(summary));
        when(nutrientTotalRepository.findByDailyWellnessSummaryDailySummaryId(42))
                .thenReturn(List.of(calorieTotal, proteinTotal));

        ProfileDashboardResponse response = service.load(userId, today);

        assertThat(response).isNotNull();
        assertThat(response.calories()).isNotNull();
        assertThat(response.calories().current()).isEqualByComparingTo("1500");
        assertThat(response.calories().goal()).isEqualByComparingTo("2000");

        assertThat(response.protein()).isNotNull();
        assertThat(response.protein().current()).isEqualByComparingTo("80");
        assertThat(response.protein().goal()).isEqualByComparingTo("120");

        // Verify the database was queried exactly ONCE, not 7 times!
        verify(nutrientTotalRepository, times(1)).findByDailyWellnessSummaryDailySummaryId(42);
    }

    @Test
    void load_neverQueriesNutrientTotals_whenSummaryIsNull() {
        Integer userId = 10;
        LocalDate today = LocalDate.of(2026, 9, 26);

        User user = new User();
        ReflectionTestUtils.setField(user, "userId", userId);
        user.setEmail("user@example.com");

        when(userRepository.findById(userId)).thenReturn(Optional.of(user));
        when(userProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.empty());
        when(wellnessProfileRepository.findByUser_UserId(userId)).thenReturn(Optional.empty());
        when(summaryRepository.findByUser_UserIdAndSummaryDate(userId, today)).thenReturn(Optional.empty());

        ProfileDashboardResponse response = service.load(userId, today);

        assertThat(response).isNotNull();
        assertThat(response.calories()).isNull();
        assertThat(response.protein()).isNull();
        assertThat(response.carbs()).isNull();
        assertThat(response.fat()).isNull();

        // When no summary exists, repository is never called
        verify(nutrientTotalRepository, never()).findByDailyWellnessSummaryDailySummaryId(any());
    }
}
