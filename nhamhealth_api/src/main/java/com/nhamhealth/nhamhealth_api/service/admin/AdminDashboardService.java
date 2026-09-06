package com.nhamhealth.nhamhealth_api.service.admin;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiFoodSuggestionRepository;
import com.nhamhealth.nhamhealth_api.repository.ai.AiRecommendationRepository;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.community.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostReportRepository;
import com.nhamhealth.nhamhealth_api.repository.community.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.notification.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyNutrientTotalRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.DailyWellnessSummaryRepository;

@Service
@Transactional(readOnly = true)
public class AdminDashboardService {

    private static final DateTimeFormatter DAY_LABEL = DateTimeFormatter.ofPattern("EEE d");
    private static final DateTimeFormatter PERIOD_LABEL = DateTimeFormatter.ofPattern("MMM d, uuuu");

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final MealRepository mealRepository;
    private final MealCategoryRepository mealCategoryRepository;
    private final DailyWellnessSummaryRepository dailyWellnessSummaryRepository;
    private final DailyNutrientTotalRepository dailyNutrientTotalRepository;
    private final AiFoodAnalysisRepository aiFoodAnalysisRepository;
    private final AiFoodSuggestionRepository aiFoodSuggestionRepository;
    private final AiRecommendationRepository aiRecommendationRepository;
    private final PostRepository postRepository;
    private final PostReportRepository postReportRepository;
    private final FollowRepository followRepository;
    private final NotificationRepository notificationRepository;

    public AdminDashboardService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            MealRepository mealRepository,
            MealCategoryRepository mealCategoryRepository,
            DailyWellnessSummaryRepository dailyWellnessSummaryRepository,
            DailyNutrientTotalRepository dailyNutrientTotalRepository,
            AiFoodAnalysisRepository aiFoodAnalysisRepository,
            AiFoodSuggestionRepository aiFoodSuggestionRepository,
            AiRecommendationRepository aiRecommendationRepository,
            PostRepository postRepository,
            PostReportRepository postReportRepository,
            FollowRepository followRepository,
            NotificationRepository notificationRepository) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.mealRepository = mealRepository;
        this.mealCategoryRepository = mealCategoryRepository;
        this.dailyWellnessSummaryRepository = dailyWellnessSummaryRepository;
        this.dailyNutrientTotalRepository = dailyNutrientTotalRepository;
        this.aiFoodAnalysisRepository = aiFoodAnalysisRepository;
        this.aiFoodSuggestionRepository = aiFoodSuggestionRepository;
        this.aiRecommendationRepository = aiRecommendationRepository;
        this.postRepository = postRepository;
        this.postReportRepository = postReportRepository;
        this.followRepository = followRepository;
        this.notificationRepository = notificationRepository;
    }

    @Cacheable("adminDashboard")
    public DashboardSnapshot loadDashboard() {
        LocalDate today = LocalDate.now();
        LocalDate startDate = today.minusDays(6);

        return new DashboardSnapshot(
                userRepository.countByStatusNot("DELETED"),
                userRepository.countByIsVerifiedTrueAndStatusNot("DELETED"),
                mealRepository.count(),
                mealRepository.countByIsPublishedTrue(),
                0,
                notificationRepository.countByIsReadFalse(),
                startDate.format(PERIOD_LABEL) + " – " + today.format(PERIOD_LABEL),
                buildActivity(startDate),
                buildCategories(),
                buildRecentUsers(),
                List.of(),
                buildNutrientMetrics(today),
                buildRecentRecommendations(),
                List.of(
                        new ModuleMetric("Wellness entries", dailyWellnessSummaryRepository.count(), "bi-heart-pulse", "/admin/daily-wellness"),
                        new ModuleMetric("AI requests", aiFoodAnalysisRepository.count() + aiRecommendationRepository.count(), "bi-stars", "/admin/ai-food-analyses"),
                        new ModuleMetric("AI suggestions", aiFoodSuggestionRepository.count(), "bi-lightbulb", "/admin/ai-food-suggestions"),
                        new ModuleMetric("Community posts", postRepository.count(), "bi-file-post", "/admin/posts"),
                        new ModuleMetric("Community reports", postReportRepository.count(), "bi-flag", "/admin/reports"),
                        new ModuleMetric("Connections", followRepository.count(), "bi-person-plus", "/admin/follows"),
                        new ModuleMetric("Notifications", notificationRepository.count(), "bi-bell", "/admin/notifications")));
    }

    private List<NutrientMetric> buildNutrientMetrics(LocalDate today) {
        List<Object[]> todayTotals = dailyNutrientTotalRepository.summarizeBySummaryDate(today);
        return List.of("Calories", "Protein", "Carbohydrates", "Fat", "Water", "Fiber", "Sugar").stream()
                .map(name -> {
                    List<Object[]> matching = todayTotals.stream()
                            .filter(total -> String.valueOf(total[0]).toLowerCase()
                            .contains(name.toLowerCase().replace("s", "")))
                            .toList();
                    BigDecimal consumed = matching.stream().map(total -> (BigDecimal) total[2])
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                    BigDecimal goal = matching.stream().map(total -> (BigDecimal) total[3])
                            .reduce(BigDecimal.ZERO, BigDecimal::add);
                    String unit = matching.isEmpty() ? defaultUnit(name) : String.valueOf(matching.getFirst()[1]);
                    long users = matching.stream().mapToLong(total -> ((Number) total[4]).longValue()).sum();
                    return new NutrientMetric(name, consumed, goal, unit, users);
                }).toList();
    }

    private String defaultUnit(String name) {
        if ("Calories".equals(name)) {
            return "kcal";
        }
        if ("Water".equals(name)) {
            return "glasses";
        }
        return "g";
    }

    private List<RecentRecommendation> buildRecentRecommendations() {
        return aiRecommendationRepository.findTop5ByOrderByCreatedAtDesc().stream()
                .map(item -> new RecentRecommendation(
                item.getUser() == null ? "Unknown user" : item.getUser().getEmail(),
                item.getResponseText(), item.getStatus(), item.getCreatedAt()))
                .toList();
    }

    private List<ActivityPoint> buildActivity(LocalDate startDate) {
        return IntStream.range(0, 7)
                .mapToObj(offset -> {
                    LocalDate date = startDate.plusDays(offset);
                    LocalDateTime dayStart = date.atStartOfDay();
                    LocalDateTime dayEnd = dayStart.plusDays(1);
                    long newUsers = userRepository.countByCreatedAtGreaterThanEqualAndCreatedAtLessThanAndStatusNot(
                            dayStart, dayEnd, "DELETED");
                    return new ActivityPoint(date.format(DAY_LABEL), newUsers);
                })
                .toList();
    }

    private List<CategoryMetric> buildCategories() {
        Map<Integer, Long> counts = mealRepository.countMealsByCategory().stream()
                .collect(Collectors.toMap(
                        row -> ((Number) row[0]).intValue(),
                        row -> ((Number) row[1]).longValue()));

        List<CategoryMetric> categories = new ArrayList<>();
        for (MealCategory category : mealCategoryRepository.findAllByOrderBySortOrderAsc()) {
            categories.add(new CategoryMetric(category.getCategoryName(), counts.getOrDefault(category.getCategoryId(), 0L)));
        }
        return categories.stream()
                .sorted(Comparator.comparing(CategoryMetric::count).reversed().thenComparing(CategoryMetric::name, String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    private List<RecentUser> buildRecentUsers() {
        List<User> users = userRepository.findTop5ByStatusNotOrderByCreatedAtDesc("DELETED");
        Map<Integer, UserProfile> profiles = userProfileRepository.findByUser_UserIdIn(
                users.stream().map(User::getUserId).toList()).stream()
                .collect(Collectors.toMap(profile -> profile.getUser().getUserId(), Function.identity()));
        return users.stream()
                .map(user -> new RecentUser(
                user.getUserId(),
                user.getInitials(),
                user.getName(),
                profiles.containsKey(user.getUserId()) ? profiles.get(user.getUserId()).getProfileImageUrl() : null,
                user.getStatus(),
                user.getCreatedAt()))
                .toList();
    }

    public record DashboardSnapshot(
            long totalUsers,
            long verifiedUsers,
            long totalMeals,
            long publishedMeals,
            long totalReviews,
            long unreadNotifications,
            String periodLabel,
            List<ActivityPoint> activity,
            List<CategoryMetric> categories,
            List<RecentUser> recentUsers,
            List<RecentReview> recentReviews,
            List<NutrientMetric> nutrients,
            List<RecentRecommendation> recentRecommendations,
            List<ModuleMetric> modules) {

    }

    public record ActivityPoint(String label, long newUsers) {

    }

    public record CategoryMetric(String name, long count) {

    }

    public record RecentUser(
            Integer id,
            String initials,
            String email,
            String profileImageUrl,
            String status,
            LocalDateTime createdAt) {

    }

    public record RecentReview(String mealName, String userEmail, Integer rating, LocalDateTime createdAt) {

    }

    public record NutrientMetric(String name, BigDecimal consumed, BigDecimal goal, String unit, long users) {

    }

    public record RecentRecommendation(String userEmail, String text, String status, LocalDateTime createdAt) {

    }

    public record ModuleMetric(String label, long count, String icon, String href) {

    }
}
