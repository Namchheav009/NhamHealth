package com.nhamhealth.nhamhealth_api.service.admin;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.request.AdminCreateUserRequest;
import com.nhamhealth.nhamhealth_api.dto.request.AdminUpdateUserRequest;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.entity.WellnessProfile;
import com.nhamhealth.nhamhealth_api.entity.Recipe;
import com.nhamhealth.nhamhealth_api.repository.auth.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.wellness.WellnessProfileRepository;
import com.nhamhealth.nhamhealth_api.service.auth.RefreshTokenService;
import com.nhamhealth.nhamhealth_api.service.recipe.RecipeFlowService;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

import jakarta.persistence.EntityManager;

@Service
public class AdminUserService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final WellnessProfileRepository wellnessProfileRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokenService;
    private final PlasgateSmsService smsService;
    private final RecipeRepository recipeRepository;
    private final RecipeFlowService recipeFlowService;
    private final EntityManager entityManager;

    public AdminUserService(
            UserRepository userRepository,
            UserProfileRepository userProfileRepository,
            WellnessProfileRepository wellnessProfileRepository,
            RoleRepository roleRepository,
            PasswordEncoder passwordEncoder,
            RefreshTokenService refreshTokenService,
            PlasgateSmsService smsService,
            RecipeRepository recipeRepository,
            RecipeFlowService recipeFlowService,
            EntityManager entityManager) {
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
        this.wellnessProfileRepository = wellnessProfileRepository;
        this.roleRepository = roleRepository;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokenService = refreshTokenService;
        this.smsService = smsService;
        this.recipeRepository = recipeRepository;
        this.recipeFlowService = recipeFlowService;
        this.entityManager = entityManager;
    }

    @Transactional(readOnly = true)
    public UserPageData loadUsers() {
        Map<Integer, UserProfile> profiles = userProfileRepository.findAll().stream()
                .filter(profile -> profile.getUser() != null && profile.getUser().getUserId() != null)
                .collect(Collectors.toMap(profile -> profile.getUser().getUserId(), Function.identity(), (left, right) -> left));
        Map<Integer, WellnessProfile> wellnessProfiles = wellnessProfileRepository.findAll().stream()
                .filter(profile -> profile.getUser() != null && profile.getUser().getUserId() != null)
                .collect(Collectors.toMap(profile -> profile.getUser().getUserId(), Function.identity(), (left, right) -> left));

        List<UserRow> users = userRepository.findAll().stream()
                .filter(user -> !"DELETED".equalsIgnoreCase(user.getStatus()))
                .sorted(Comparator.comparing(User::getCreatedAt, Comparator.nullsLast(Comparator.reverseOrder())))
                .map(user -> toRow(user, profiles.get(user.getUserId()), wellnessProfiles.get(user.getUserId())))
                .toList();

        long verifiedUsers = users.stream().filter(UserRow::verified).count();
        long completeProfiles = users.stream().filter(UserRow::profileComplete).count();
        long activeUsers = users.stream().filter(user -> "ACTIVE".equalsIgnoreCase(user.status())).count();

        return new UserPageData(users, users.stream().limit(5).toList(), users.size(), verifiedUsers, completeProfiles, activeUsers);
    }

    @Transactional
    @CacheEvict(value = "adminDashboard", allEntries = true)
    public UserRow createUser(AdminCreateUserRequest request) {
        AccountIdentity identity = accountIdentity(request.email());
        ensureIdentityAvailable(identity, null);

        User user = new User();
        user.setEmail(identity.email());
        user.setPhoneNumber(identity.phoneNumber());
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(requiredRole(request.role()));
        String status = request.status() == null || request.status().isBlank()
                ? "ACTIVE"
                : request.status().trim().toUpperCase(Locale.ROOT);
        boolean verified = request.verified() == null || request.verified();
        user.setStatus(status);
        user.setIsVerified(verified);
        user.setVerifiedAt(verified ? LocalDateTime.now() : null);
        user = userRepository.save(user);

        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName(request.fullName().trim());
        profile.setProfileImageUrl(normalizeImageUrl(request.profileImageUrl()));
        if (identity.phoneNumber() != null) {
            profile.setPhoneNumber(identity.phoneNumber());
            profile.setIsPhoneVerified(verified);
            profile.setPhoneVerifiedAt(verified ? now : null);
        }
        profile.setCreatedAt(now);
        profile.setUpdatedAt(now);
        userProfileRepository.save(profile);

        return toRow(user, profile, null);
    }

    @Transactional
    @CacheEvict(value = "adminDashboard", allEntries = true)
    public UserRow updateUser(Integer userId, AdminUpdateUserRequest request, String currentAdminEmail) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User account was not found"));
        boolean editingSelf = currentAdminEmail != null && ((user.getEmail() != null && user.getEmail().equalsIgnoreCase(currentAdminEmail))
                || (user.getPhoneNumber() != null && user.getPhoneNumber().equalsIgnoreCase(currentAdminEmail)));
        AccountIdentity identity = accountIdentity(request.email());
        ensureIdentityAvailable(identity, userId);

        String role = request.role().trim().toUpperCase(Locale.ROOT);
        String status = request.status().trim().toUpperCase(Locale.ROOT);
        if (editingSelf && (!"ADMIN".equals(role) || !"ACTIVE".equals(status) || !request.verified())) {
            throw new IllegalArgumentException("You cannot remove your own administrator access");
        }

        boolean passwordChanged = request.password() != null && !request.password().isBlank();
        boolean securityChanged = !Objects.equals(user.getEmail(), identity.email())
                || !Objects.equals(user.getPhoneNumber(), identity.phoneNumber())
                || !role.equalsIgnoreCase(user.getRoleLabel())
                || !status.equalsIgnoreCase(user.getStatus())
                || request.verified() != Boolean.TRUE.equals(user.getIsVerified())
                || passwordChanged;

        user.setEmail(identity.email());
        user.setPhoneNumber(identity.phoneNumber());
        user.setRole(requiredRole(role));
        user.setStatus(status);
        user.setIsVerified(request.verified());
        if (!request.verified()) {
            user.setVerifiedAt(null);
        } else if (user.getVerifiedAt() == null) {
            user.setVerifiedAt(LocalDateTime.now());
        }
        if (passwordChanged) {
            user.setPasswordHash(passwordEncoder.encode(request.password()));
        }
        user = userRepository.save(user);
        User savedUser = user;

        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = userProfileRepository.findByUser_UserId(userId)
                .orElseGet(() -> createProfile(savedUser, now));
        profile.setFullName(request.fullName().trim());
        if (request.profileImageUrl() != null) {
            profile.setProfileImageUrl(normalizeImageUrl(request.profileImageUrl()));
        }
        if (identity.phoneNumber() != null) {
            profile.setPhoneNumber(identity.phoneNumber());
            profile.setIsPhoneVerified(request.verified());
            profile.setPhoneVerifiedAt(request.verified() ? LocalDateTime.now() : null);
        }
        profile.setUpdatedAt(now);
        userProfileRepository.save(profile);

        if (securityChanged) {
            refreshTokenService.revokeAll(user);
        }

        WellnessProfile wellnessProfile = wellnessProfileRepository.findByUser_UserId(userId).orElse(null);
        return toRow(user, profile, wellnessProfile);
    }

    @Transactional
    @CacheEvict(value = {
            "adminDashboard", "mealCategories", "activeMealCategories", "tags",
            "mealTagNames", "servingSizes", "nutrients", "foodCorrectionMatches",
            "foodSearch", "meals", "mealDetail", "moods"
    }, allEntries = true)
    public void deleteUser(Integer userId, String currentAdminIdentifier) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User account was not found"));
        boolean isSelf = currentAdminIdentifier != null && ((user.getEmail() != null && user.getEmail().equalsIgnoreCase(currentAdminIdentifier))
                || (user.getPhoneNumber() != null && user.getPhoneNumber().equalsIgnoreCase(currentAdminIdentifier)));
        if (isSelf) {
            throw new IllegalArgumentException("You cannot delete your own account");
        }

        // 1. Revoke refresh tokens and sessions
        refreshTokenService.revokeAll(user);
        entityManager.createNativeQuery("DELETE FROM refresh_tokens WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 2. Delete recipes authored by this user
        // Delete shares first, then original recipes, cascading all media, steps, ingredients, etc.
        List<Recipe> userRecipes = recipeRepository.findByAuthorUserIdOrderByUpdatedAtDesc(userId);
        List<Recipe> sharedRecipes = userRecipes.stream()
                .filter(r -> r.getSharedFrom() != null)
                .toList();
        List<Recipe> originalRecipes = userRecipes.stream()
                .filter(r -> r.getSharedFrom() == null)
                .toList();

        for (Recipe r : sharedRecipes) {
            recipeFlowService.adminDelete(r.getRecipeId());
        }
        for (Recipe r : originalRecipes) {
            recipeFlowService.adminDelete(r.getRecipeId());
        }
        entityManager.flush();

        // Fallback cleanup in case any orphaned post reference remained
        entityManager.createNativeQuery("DELETE FROM user_meal_posts WHERE author_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 3. User recipe AI checks where user was the creator
        entityManager.createNativeQuery("DELETE FROM user_recipe_ai_checks WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 4. User interactions on other posts:
        // Delete comment likes and reports on comments written by this user
        entityManager.createNativeQuery("DELETE FROM comment_likes WHERE comment_id IN "
                + "(SELECT comment_id FROM post_comments WHERE user_id = :userId)")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM post_reports WHERE comment_id IN "
                + "(SELECT comment_id FROM post_comments WHERE user_id = :userId)")
                .setParameter("userId", userId)
                .executeUpdate();

        // Unlink replies to this user's comments to maintain tree integrity
        entityManager.createNativeQuery("UPDATE post_comments SET parent_comment_id = NULL WHERE parent_comment_id IN "
                + "(SELECT comment_id FROM post_comments WHERE user_id = :userId)")
                .setParameter("userId", userId)
                .executeUpdate();

        // Delete comments made by this user
        entityManager.createNativeQuery("DELETE FROM post_comments WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // Delete user's likes, favorites, saved recipes on any post
        entityManager.createNativeQuery("DELETE FROM comment_likes WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM post_likes WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM post_favorites WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM saved_recipes WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 5. Social relationships and notifications
        entityManager.createNativeQuery("DELETE FROM follows WHERE follower_user_id = :userId OR following_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM notifications WHERE user_id = :userId OR actor_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM push_notification_devices WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 6. Meal planning & favorites
        entityManager.createNativeQuery("DELETE FROM meal_plans WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM meal_favorites WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 7. Daily wellness summaries and nutrient totals
        entityManager.createNativeQuery("DELETE FROM daily_nutrient_totals WHERE daily_summary_id IN "
                + "(SELECT daily_summary_id FROM daily_wellness_summaries WHERE user_id = :userId)")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM daily_wellness_summaries WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 8. AI food analyses and suggestions / nutrients
        entityManager.createNativeQuery("DELETE FROM ai_food_analysis_nutrients WHERE ai_food_analysis_id IN "
                + "(SELECT ai_food_analysis_id FROM ai_food_analyses WHERE user_id = :userId)")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM ai_food_suggestions WHERE ai_food_analysis_id IN "
                + "(SELECT ai_food_analysis_id FROM ai_food_analyses WHERE user_id = :userId)")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM ai_food_analyses WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 9. AI recommendations and items
        entityManager.createNativeQuery("DELETE FROM ai_recommendation_items WHERE recommendation_id IN "
                + "(SELECT recommendation_id FROM ai_recommendations WHERE user_id = :userId)")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM ai_recommendations WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 10. Unlink any meals created by this user
        entityManager.createNativeQuery("UPDATE meals SET created_by_user_id = NULL WHERE created_by_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 11. Moderation & reports
        entityManager.createNativeQuery("DELETE FROM user_profile_reports WHERE reported_user_id = :userId OR reported_by_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("UPDATE user_profile_reports SET reviewed_by_user_id = NULL WHERE reviewed_by_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        entityManager.createNativeQuery("DELETE FROM post_reports WHERE reported_by_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("UPDATE post_reports SET reviewed_by_user_id = NULL WHERE reviewed_by_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        entityManager.createNativeQuery("DELETE FROM report_attachments WHERE report_id IN "
                + "(SELECT report_id FROM reports WHERE reporter_user_id = :userId OR reported_user_id = :userId)")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM reports WHERE reporter_user_id = :userId OR reported_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("UPDATE reports SET reviewed_by = NULL WHERE reviewed_by = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        entityManager.createNativeQuery("DELETE FROM moderation_actions WHERE target_user_id = :userId OR admin_user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("UPDATE moderation_actions SET reversed_by = NULL WHERE reversed_by = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        entityManager.createNativeQuery("DELETE FROM moderation_appeals WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("UPDATE moderation_appeals SET reviewed_by = NULL WHERE reviewed_by = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 12. User settings, verification codes, reset tokens, auth providers, wellness & user profiles
        entityManager.createNativeQuery("DELETE FROM user_settings WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM verification_codes WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM password_reset_tokens WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM user_auth_providers WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM wellness_profiles WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();
        entityManager.createNativeQuery("DELETE FROM user_profiles WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        // 13. Permanently delete the user row from users table
        entityManager.createNativeQuery("DELETE FROM users WHERE user_id = :userId")
                .setParameter("userId", userId)
                .executeUpdate();

        entityManager.flush();
        entityManager.clear();
    }

    @Transactional
    public void revokeSessions(Integer userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User account was not found"));
        if ("DELETED".equalsIgnoreCase(user.getStatus())) {
            throw new IllegalArgumentException("Deleted accounts do not have active sessions");
        }
        refreshTokenService.revokeAll(user);
        userRepository.saveAndFlush(user);
    }

    @Transactional
    @CacheEvict(value = "adminDashboard", allEntries = true)
    public UserRow updateStatus(Integer userId, String requestedStatus, String currentAdminIdentifier) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User account was not found"));
        String status = requestedStatus == null ? "" : requestedStatus.trim().toUpperCase(Locale.ROOT);
        if (!List.of("ACTIVE", "PENDING", "SUSPENDED", "BANNED").contains(status)) {
            throw new IllegalArgumentException("Status must be ACTIVE, PENDING, SUSPENDED, or BANNED");
        }
        boolean isSelf = currentAdminIdentifier != null && ((user.getEmail() != null && user.getEmail().equalsIgnoreCase(currentAdminIdentifier))
                || (user.getPhoneNumber() != null && user.getPhoneNumber().equalsIgnoreCase(currentAdminIdentifier)));
        if (isSelf && !"ACTIVE".equals(status)) {
            throw new IllegalArgumentException("You cannot suspend your own administrator account");
        }

        user.setStatus(status);
        userRepository.saveAndFlush(user);
        if (!"ACTIVE".equals(status)) {
            refreshTokenService.revokeAll(user);
        }
        UserProfile profile = userProfileRepository.findByUser_UserId(userId).orElse(null);
        WellnessProfile wellnessProfile = wellnessProfileRepository.findByUser_UserId(userId).orElse(null);
        return toRow(user, profile, wellnessProfile);
    }

    private UserProfile createProfile(User user, LocalDateTime now) {
        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName(defaultName(user.getEmail()));
        profile.setCreatedAt(now);
        profile.setUpdatedAt(now);
        return profile;
    }

    private Role requiredRole(String requestedRole) {
        String roleName = requestedRole.trim().toUpperCase(Locale.ROOT);
        return roleRepository.findByRoleNameIgnoreCase(roleName)
                .orElseGet(() -> {
                    Role role = new Role();
                    role.setRoleName(roleName);
                    role.setDescription("ADMIN".equals(roleName) ? "Administrator" : "Standard user");
                    return roleRepository.save(role);
                });
    }

    private UserRow toRow(User user, UserProfile profile, WellnessProfile wellnessProfile) {
        String name = profile != null && profile.getFullName() != null && !profile.getFullName().isBlank()
                ? profile.getFullName()
                : (user.getEmail() != null && !user.getEmail().isBlank()
                ? user.getEmail()
                : (user.getPhoneNumber() != null ? user.getPhoneNumber() : "Unknown"));
        String email = user.getEmail() != null && !user.getEmail().isBlank()
                ? user.getEmail()
                : (user.getPhoneNumber() != null ? user.getPhoneNumber() : "No email");
        return new UserRow(
                user.getUserId(),
                name,
                initials(name),
                email,
                profile != null ? profile.getProfileImageUrl() : null,
                user.getRole() != null ? user.getRole().getRoleName() : "USER",
                user.getStatus() == null ? "UNKNOWN" : user.getStatus(),
                Boolean.TRUE.equals(user.getIsVerified()),
                profile != null && wellnessProfile != null,
                user.getCreatedAt(),
                user.getLastLoginAt());
    }

    private String initials(String name) {
        if (name == null || name.isBlank()) {
            return "NA";
        }
        String[] words = name.trim().split("\\s+");
        if (words.length == 1) {
            return words[0].substring(0, Math.min(2, words[0].length())).toUpperCase(Locale.ROOT);
        }
        return (words[0].substring(0, 1) + words[words.length - 1].substring(0, 1)).toUpperCase(Locale.ROOT);
    }

    private String normalizeImageUrl(String imageUrl) {
        return imageUrl == null || imageUrl.isBlank() ? null : imageUrl.trim();
    }

    private String defaultName(String email) {
        int at = email == null ? -1 : email.indexOf('@');
        return at > 0 ? email.substring(0, at) : "Nham Health user";
    }

    private AccountIdentity accountIdentity(String rawIdentifier) {
        String identifier = rawIdentifier == null ? "" : rawIdentifier.trim();
        if (identifier.contains("@")) {
            String email = identifier.toLowerCase(Locale.ROOT);
            int at = email.indexOf('@');
            boolean valid = at > 0
                    && at == email.lastIndexOf('@')
                    && at < email.length() - 3
                    && email.indexOf('.', at + 2) > at + 1
                    && email.chars().noneMatch(Character::isWhitespace);
            if (!valid) {
                throw new IllegalArgumentException("Please enter a valid email or phone number");
            }
            return new AccountIdentity(email, null);
        }

        return new AccountIdentity(null, smsService.normalizePhoneNumber(identifier));
    }

    private void ensureIdentityAvailable(AccountIdentity identity, Integer currentUserId) {
        if (identity.email() != null) {
            userRepository.findByEmailIgnoreCase(identity.email())
                    .filter(existing -> !existing.getUserId().equals(currentUserId))
                    .ifPresent(existing -> {
                        throw new IllegalArgumentException("An account with this email already exists");
                    });
            return;
        }

        userRepository.findByPhoneNumber(identity.phoneNumber())
                .filter(existing -> !existing.getUserId().equals(currentUserId))
                .ifPresent(existing -> {
                    throw new IllegalArgumentException("An account with this phone number already exists");
                });
    }

    private record AccountIdentity(String email, String phoneNumber) {
    }

    public record UserPageData(
            List<UserRow> users,
            List<UserRow> recentUsers,
            long totalUsers,
            long verifiedUsers,
            long completeProfiles,
            long activeUsers) {

    }

    public record UserRow(
            Integer id,
            String name,
            String initials,
            String email,
            String profileImageUrl,
            String role,
            String status,
            boolean verified,
            boolean profileComplete,
            LocalDateTime createdAt,
            LocalDateTime lastLoginAt) {

    }
}
