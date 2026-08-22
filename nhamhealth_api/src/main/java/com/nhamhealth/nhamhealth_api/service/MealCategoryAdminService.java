package com.nhamhealth.nhamhealth_api.service;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Caching;

import com.nhamhealth.nhamhealth_api.dto.request.AdminMealCategoryRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AdminMealCategoryDto;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.repository.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.MealRepository;

@Service
public class MealCategoryAdminService {

    private final MealCategoryRepository mealCategoryRepository;
    private final MealRepository mealRepository;

    public MealCategoryAdminService(MealCategoryRepository mealCategoryRepository, MealRepository mealRepository) {
        this.mealCategoryRepository = mealCategoryRepository;
        this.mealRepository = mealRepository;
    }

        @Transactional
        @Caching(evict = {
            @CacheEvict(value = "mealCategories", allEntries = true),
            @CacheEvict(value = "activeMealCategories", allEntries = true)
        })
    public AdminMealCategoryDto create(AdminMealCategoryRequest request) {
        String name = request.categoryName().trim();
        if (mealCategoryRepository.findByCategoryNameIgnoreCase(name).isPresent()) {
            throw new IllegalArgumentException("A meal category with this name already exists");
        }
        MealCategory category = new MealCategory();
        apply(category, request);
        if (category.getSortOrder() == null) {
            category.setSortOrder(nextSortOrder());
        }
        return toDto(mealCategoryRepository.save(category));
    }

        @Transactional
        @Caching(evict = {
            @CacheEvict(value = "mealCategories", allEntries = true),
            @CacheEvict(value = "activeMealCategories", allEntries = true)
        })
    public AdminMealCategoryDto update(Integer categoryId, AdminMealCategoryRequest request) {
        MealCategory category = getCategory(categoryId);
        String name = request.categoryName().trim();
        mealCategoryRepository.findByCategoryNameIgnoreCase(name)
                .filter(existing -> !existing.getCategoryId().equals(categoryId))
                .ifPresent(existing -> { throw new IllegalArgumentException("A meal category with this name already exists"); });
        apply(category, request);
        return toDto(mealCategoryRepository.save(category));
    }

        @Transactional
        @Caching(evict = {
            @CacheEvict(value = "mealCategories", allEntries = true),
            @CacheEvict(value = "activeMealCategories", allEntries = true)
        })
    public void delete(Integer categoryId) {
        MealCategory category = getCategory(categoryId);
        if (mealRepository.countByCategoryCategoryId(categoryId) > 0) {
            throw new IllegalArgumentException("This category still has meals. Set it inactive instead of deleting it.");
        }
        mealCategoryRepository.delete(category);
    }

    private MealCategory getCategory(Integer categoryId) {
        return mealCategoryRepository.findById(categoryId)
                .orElseThrow(() -> new IllegalArgumentException("Meal category was not found"));
    }

    private void apply(MealCategory category, AdminMealCategoryRequest request) {
        category.setCategoryName(request.categoryName().trim());
        category.setDescription(blankToNull(request.description()));
        category.setIsActive(request.active());
        category.setSortOrder(request.sortOrder() == null ? nextSortOrder() : request.sortOrder());
    }

    private int nextSortOrder() {
        return mealCategoryRepository.findAllByOrderBySortOrderAsc().stream()
                .map(MealCategory::getSortOrder)
                .filter(order -> order != null)
                .max(Integer::compareTo)
                .orElse(0) + 1;
    }

    private String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private AdminMealCategoryDto toDto(MealCategory category) {
        return new AdminMealCategoryDto(
                category.getCategoryId(),
                category.getCategoryName(),
                category.getDescription(),
                Boolean.TRUE.equals(category.getIsActive()),
                category.getSortOrder(),
                mealRepository.countByCategoryCategoryId(category.getCategoryId()));
    }
}
