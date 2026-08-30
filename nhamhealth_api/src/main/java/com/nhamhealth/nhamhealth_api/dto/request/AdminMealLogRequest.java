package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record AdminMealLogRequest(
        @NotNull(message = "User is required") @Positive(message = "User is invalid") Integer userId,
        @NotNull(message = "Meal type is required") @Positive(message = "Meal type is invalid") Integer mealLogTypeId,
        @Positive(message = "Meal is invalid") Integer mealId,
        @Positive(message = "Serving size is invalid") Integer servingSizeId,
        @Size(max = 150, message = "Custom food name must not exceed 150 characters") String customFoodName,
        @NotNull(message = "Quantity is required")
        @DecimalMin(value = "0.01", message = "Quantity must be greater than zero")
        @Digits(integer = 10, fraction = 2, message = "Quantity must have at most 10 whole digits and 2 decimals")
        BigDecimal quantity,
        @NotBlank(message = "Entry method is required")
        @Size(max = 20, message = "Entry method must not exceed 20 characters") String entryMethod,
        @NotNull(message = "Logged date and time is required") LocalDateTime loggedAt,
        String notes) {

    @AssertTrue(message = "Select a saved meal or enter a custom food name")
    public boolean hasFood() {
        return mealId != null || (customFoodName != null && !customFoodName.isBlank());
    }
}
