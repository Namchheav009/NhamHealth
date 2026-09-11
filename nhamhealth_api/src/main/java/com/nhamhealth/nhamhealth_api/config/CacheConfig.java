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

        @Bean
        public CacheManager cacheManager() {
                CaffeineCacheManager manager = new CaffeineCacheManager();
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
                                CACHE_MEAL_DETAIL));

                // Default specification for general caches: max 500 items, 10 min TTL
                manager.setCaffeine(Caffeine.newBuilder()
                                .maximumSize(500)
                                .expireAfterWrite(Duration.ofMinutes(10))
                                .recordStats());

                // Reference data tier (rarely changes): 1 hour TTL, max 200 items
                var referenceDataCache = Caffeine.newBuilder()
                                .maximumSize(200)
                                .expireAfterWrite(Duration.ofHours(1))
                                .recordStats()
                                .build();
                manager.registerCustomCache(CACHE_MEAL_CATEGORIES, referenceDataCache);
                manager.registerCustomCache(CACHE_ACTIVE_MEAL_CATEGORIES, referenceDataCache);
                manager.registerCustomCache(CACHE_TAGS, referenceDataCache);
                manager.registerCustomCache(CACHE_SERVING_SIZES, referenceDataCache);
                manager.registerCustomCache(CACHE_NUTRIENTS, referenceDataCache);
                manager.registerCustomCache(CACHE_MEAL_TAG_NAMES, referenceDataCache);

                // Food catalog search results: 30 minutes TTL, max 1000 items
                var foodSearchCache = Caffeine.newBuilder()
                                .maximumSize(1000)
                                .expireAfterWrite(Duration.ofMinutes(30))
                                .recordStats()
                                .build();
                manager.registerCustomCache(CACHE_FOOD_SEARCH, foodSearchCache);

                // Meal catalog and details: 15 minutes TTL, max 500 items
                var mealCache = Caffeine.newBuilder()
                                .maximumSize(500)
                                .expireAfterWrite(Duration.ofMinutes(15))
                                .recordStats()
                                .build();
                manager.registerCustomCache(CACHE_MEALS, mealCache);
                manager.registerCustomCache(CACHE_MEAL_DETAIL, mealCache);

                // Admin dashboard: 2 minutes TTL, max 20 items
                var adminDashboardCache = Caffeine.newBuilder()
                                .maximumSize(20)
                                .expireAfterWrite(Duration.ofMinutes(2))
                                .recordStats()
                                .build();
                manager.registerCustomCache(CACHE_ADMIN_DASHBOARD, adminDashboardCache);

                return manager;
        }
}
