package com.nhamhealth.nhamhealth_api.dto.response;

import com.nhamhealth.nhamhealth_api.entity.MealCategory;

/** A meal category available for selection in the mobile application. */
public record MealCategoryResponse(Integer id, String name) {
    public static MealCategoryResponse from(MealCategory category) {
        return new MealCategoryResponse(category.getCategoryId(), category.getCategoryName());
    }
}
