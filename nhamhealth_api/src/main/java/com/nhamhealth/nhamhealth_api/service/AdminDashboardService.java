package com.nhamhealth.nhamhealth_api.service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.IntStream;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.entity.Meal;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.MealLog;
import com.nhamhealth.nhamhealth_api.entity.Review;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiFoodAnalysisRepository;
import com.nhamhealth.nhamhealth_api.repository.AiFoodSuggestionRepository;
import com.nhamhealth.nhamhealth_api.repository.AiRecommendationRepository;
import com.nhamhealth.nhamhealth_api.repository.ChatRepository;
import com.nhamhealth.nhamhealth_api.repository.DailyWellnessSummaryRepository;
import com.nhamhealth.nhamhealth_api.repository.FollowRepository;
import com.nhamhealth.nhamhealth_api.repository.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.MealLogRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;
import com.nhamhealth.nhamhealth_api.repository.MessageRepository;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.PostReportRepository;
import com.nhamhealth.nhamhealth_api.repository.PostRepository;
import com.nhamhealth.nhamhealth_api.repository.ReviewRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Service
@Transactional(readOnly = true)
public class AdminDashboardService {

    private static final DateTimeFormatter DAY_LABEL = DateTimeFormatter.ofPattern("EEE d");
    private static final DateTimeFormatter PERIOD_LABEL = DateTimeFormatter.ofPattern("MMM d, uuuu");

    private final UserRepository userRepository;
    private final MealRepository mealRepository;
    private final MealCategoryRepository mealCategoryRepository;
    private final MealLogRepository mealLogRepository;
    private final ReviewRepository reviewRepository;
    private final DailyWellnessSummaryRepository dailyWellnessSummaryRepository;
    private final AiFoodAnalysisRepository aiFoodAnalysisRepository;
    private final AiFoodSuggestionRepository aiFoodSuggestionRepository;
    private final AiRecommendationRepository aiRecommendationRepository;
    private final PostRepository postRepository;
    private final PostReportRepository postReportRepository;
    private final FollowRepository followRepository;
    private final ChatRepository chatRepository;
    private final MessageRepository messageRepository;
    private final NotificationRepository notificationRepository;

    public AdminDashboardService(
            UserRepository userRepository,
            MealRepository mealRepository,
            MealCategoryRepository mealCategoryRepository,
            MealLogRepository mealLogRepository,
            ReviewRepository reviewRepository,
            DailyWellnessSummaryRepository dailyWellnessSummaryRepository,
            AiFoodAnalysisRepository aiFoodAnalysisRepository,
            AiFoodSuggestionRepository aiFoodSuggestionRepository,
            AiRecommendationRepository aiRecommendationRepository,
            PostRepository postRepository,
            PostReportRepository postReportRepository,
            FollowRepository followRepository,
            ChatRepository chatRepository,
            MessageRepository messageRepository,
            NotificationRepository notificationRepository) {
        this.userRepository = userRepository;
        this.mealRepository = mealRepository;
        this.mealCategoryRepository = mealCategoryRepository;
        this.mealLogRepository = mealLogRepository;
        this.reviewRepository = reviewRepository;
        this.dailyWellnessSummaryRepository = dailyWellnessSummaryRepository;
        this.aiFoodAnalysisRepository = aiFoodAnalysisRepository;
        this.aiFoodSuggestionRepository = aiFoodSuggestionRepository;
        this.aiRecommendationRepository = aiRecommendationRepository;
        this.postRepository = postRepository;
        this.postReportRepository = postReportRepository;
        this.followRepository = followRepository;
        this.chatRepository = chatRepository;
        this.messageRepository = messageRepository;
        this.notificationRepository = notificationRepository;
    }

    public DashboardSnapshot loadDashboard() {
        List<User> users = userRepository.findAll();
        List<Meal> meals = mealRepository.findAll();
        List<MealLog> mealLogs = mealLogRepository.findAll();
        List<Review> reviews = reviewRepository.findAll();
        LocalDate today = LocalDate.now();
        LocalDate startDate = today.minusDays(6);

        long publishedMeals = meals.stream().filter(meal -> Boolean.TRUE.equals(meal.getIsPublished())).count();
        long verifiedUsers = users.stream().filter(user -> Boolean.TRUE.equals(user.getIsVerified())).count();
        long unreadNotifications = notificationRepository.findAll().stream()
                .filter(notification -> !Boolean.TRUE.equals(notification.getIsRead()))
                .count();

        return new DashboardSnapshot(
                users.size(),
                verifiedUsers,
                meals.size(),
                publishedMeals,
                mealLogs.size(),
                reviews.size(),
                unreadNotifications,
                startDate.format(PERIOD_LABEL) + " – " + today.format(PERIOD_LABEL),
                buildActivity(startDate, users, mealLogs),
                buildCategories(meals),
                buildRecentUsers(users),
                buildRecentReviews(reviews),
                List.of(
                        new ModuleMetric("Wellness entries", dailyWellnessSummaryRepository.count(), "bi-heart-pulse", "/admin/daily-wellness"),
                        new ModuleMetric("AI requests", aiFoodAnalysisRepository.count() + aiRecommendationRepository.count(), "bi-stars", "/admin/ai-food-analyses"),
                        new ModuleMetric("AI suggestions", aiFoodSuggestionRepository.count(), "bi-lightbulb", "/admin/ai-food-suggestions"),
                        new ModuleMetric("Community posts", postRepository.count(), "bi-file-post", "/admin/posts"),
                        new ModuleMetric("Community reports", postReportRepository.count(), "bi-flag", "/admin/reports"),
                        new ModuleMetric("Connections", followRepository.count(), "bi-person-plus", "/admin/follows"),
                        new ModuleMetric("Conversations", chatRepository.count() + messageRepository.count(), "bi-chat-dots", "/admin/chats"),
                        new ModuleMetric("Notifications", notificationRepository.count(), "bi-bell", "/admin/notifications")));
    }

    private List<ActivityPoint> buildActivity(LocalDate startDate, List<User> users, List<MealLog> mealLogs) {
        return IntStream.range(0, 7)
                .mapToObj(offset -> {
                    LocalDate date = startDate.plusDays(offset);
                    long newUsers = users.stream().filter(user -> date.equals(toDate(user.getCreatedAt()))).count();
                    long logs = mealLogs.stream().filter(log -> date.equals(toDate(log.getLoggedAt()))).count();
                    return new ActivityPoint(date.format(DAY_LABEL), newUsers, logs);
                })
                .toList();
    }

    private List<CategoryMetric> buildCategories(List<Meal> meals) {
        Map<Integer, Long> counts = new HashMap<>();
        for (Meal meal : meals) {
            if (meal.getCategory() != null && meal.getCategory().getCategoryId() != null) {
                counts.merge(meal.getCategory().getCategoryId(), 1L, Long::sum);
            }
        }

        List<CategoryMetric> categories = new ArrayList<>();
        for (MealCategory category : mealCategoryRepository.findAllByOrderBySortOrderAsc()) {
            categories.add(new CategoryMetric(category.getCategoryName(), counts.getOrDefault(category.getCategoryId(), 0L)));
        }
        return categories.stream()
                .sorted(Comparator.comparing(CategoryMetric::count).reversed().thenComparing(CategoryMetric::name, String.CASE_INSENSITIVE_ORDER))
                .toList();
    }

    private List<RecentUser> buildRecentUsers(List<User> users) {
        return users.stream()
                .sorted(Comparator.comparing(User::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(5)
                .map(user -> new RecentUser(user.getInitials(), user.getEmail(), user.getStatus(), user.getCreatedAt()))
                .toList();
    }

    private List<RecentReview> buildRecentReviews(List<Review> reviews) {
        return reviews.stream()
                .sorted(Comparator.comparing(Review::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(5)
                .map(review -> new RecentReview(
                        review.getMeal() != null ? review.getMeal().getMealName() : "Unknown meal",
                        review.getUser() != null ? review.getUser().getEmail() : "Unknown user",
                        review.getRating(),
                        review.getCreatedAt()))
                .toList();
    }

    private LocalDate toDate(LocalDateTime value) {
        return value == null ? null : value.toLocalDate();
    }

    public record DashboardSnapshot(
            long totalUsers,
            long verifiedUsers,
            long totalMeals,
            long publishedMeals,
            long totalMealLogs,
            long totalReviews,
            long unreadNotifications,
            String periodLabel,
            List<ActivityPoint> activity,
            List<CategoryMetric> categories,
            List<RecentUser> recentUsers,
            List<RecentReview> recentReviews,
            List<ModuleMetric> modules) {
    }

    public record ActivityPoint(String label, long newUsers, long mealLogs) {
    }

    public record CategoryMetric(String name, long count) {
    }

    public record RecentUser(String initials, String email, String status, LocalDateTime createdAt) {
    }

    public record RecentReview(String mealName, String userEmail, Integer rating, LocalDateTime createdAt) {
    }

    public record ModuleMetric(String label, long count, String icon, String href) {
    }
}
