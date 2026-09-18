package com.nhamhealth.nhamhealth_api.config;

import java.time.Duration;
import java.util.List;

import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import com.github.benmanes.caffeine.cache.Caffeine;

@Configuration
@EnableCaching
public class CacheConfig {

        public static final String CACHE_ADMIN_DASHBOARD = "adminDashboard";
        public static final String CACHE_MEAL_CATEGORIES = "mealCategories";
        public static final String CACHE_ACTIVE_MEAL_CATEGORIES = "activeMealCategories";
        public static final String CACHE_TAGS = "tags";
        public static final String CACHE_MEAL_TAG_NAMES = "mealTagNames";
        public static final String CACHE_SERVING_SIZES = "servingSizes";
        public static final String CACHE_NUTRIENTS = "nutrients";
        public static final String CACHE_FOOD_CORRECTION_MATCHES = "foodCorrectionMatches";
        public static final String CACHE_FOOD_SEARCH = "foodSearch";
        public static final String CACHE_MEALS = "meals";
        public static final String CACHE_MEAL_DETAIL = "mealDetail";
        public static final String CACHE_MOODS = "moods";

        @Bean
        public CacheManager cacheManager() {
                CaffeineCacheManager manager = new CaffeineCacheManager() {
                        @Override
                        public org.springframework.cache.Cache getCache(String name) {
                                org.springframework.cache.Cache cache = super.getCache(name);
                                return cache != null ? cache : createCaffeineCache(name);
                        }
                };
                manager.setCacheNames(List.of(
                                CACHE_ADMIN_DASHBOARD,
                                CACHE_MEAL_CATEGORIES,
                                CACHE_ACTIVE_MEAL_CATEGORIES,
                                CACHE_TAGS,
                                CACHE_MEAL_TAG_NAMES,
                                CACHE_SERVING_SIZES,
                                CACHE_NUTRIENTS,
                                CACHE_FOOD_CORRECTION_MATCHES,
                                CACHE_FOOD_SEARCH,
                                CACHE_MEALS,
                                CACHE_MEAL_DETAIL,
                                CACHE_MOODS));

                // Default specification for general caches: max 500 items, 10 min TTL
                manager.setCaffeine(Caffeine.newBuilder()
                                .maximumSize(500)
                                .expireAfterWrite(Duration.ofMinutes(10))
                                .recordStats());

                // Reference data tier (rarely changes): 1 hour TTL, max 200 items
                manager.registerCustomCache(CACHE_MEAL_CATEGORIES, buildCache(200, Duration.ofHours(1)));
                manager.registerCustomCache(CACHE_ACTIVE_MEAL_CATEGORIES, buildCache(200, Duration.ofHours(1)));
                manager.registerCustomCache(CACHE_TAGS, buildCache(200, Duration.ofHours(1)));
                manager.registerCustomCache(CACHE_SERVING_SIZES, buildCache(200, Duration.ofHours(1)));
                manager.registerCustomCache(CACHE_NUTRIENTS, buildCache(200, Duration.ofHours(1)));
                manager.registerCustomCache(CACHE_MEAL_TAG_NAMES, buildCache(200, Duration.ofHours(1)));
                manager.registerCustomCache(CACHE_MOODS, buildCache(200, Duration.ofHours(1)));

                // Food catalog search results: 30 minutes TTL, max 1000 items
                manager.registerCustomCache(CACHE_FOOD_SEARCH, buildCache(1000, Duration.ofMinutes(30)));

                // Meal catalog and details: 15 minutes TTL, max 500 items
                manager.registerCustomCache(CACHE_MEALS, buildCache(500, Duration.ofMinutes(15)));
                manager.registerCustomCache(CACHE_MEAL_DETAIL, buildCache(500, Duration.ofMinutes(15)));

                // Admin dashboard: 2 minutes TTL, max 20 items
                manager.registerCustomCache(CACHE_ADMIN_DASHBOARD, buildCache(20, Duration.ofMinutes(2)));

                return manager;
        }

        private com.github.benmanes.caffeine.cache.Cache<Object, Object> buildCache(long maxSize, Duration ttl) {
                return Caffeine.newBuilder()
                                .maximumSize(maxSize)
                                .expireAfterWrite(ttl)
                                .recordStats()
                                .build();
        }
}
