package com.nhamhealth.nhamhealth_api.dto.request;

import java.math.BigDecimal;
import java.util.List;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;

public record ScrapedMealImportRequest(
        @NotBlank @Size(max = 150) String mealName,
        @Size(max = 150) String khmerName,
        @Size(max = 500) String description,
        @Size(max = 1000) String descriptionKm,
        @NotBlank @Size(max = 100) String categoryName,
        @Size(max = 100) String categoryNameKm,
        @DecimalMin(value = "0", message = "calories must be non-negative") BigDecimal calories,
        @DecimalMin(value = "0", message = "proteinGrams must be non-negative") BigDecimal proteinGrams,
        @DecimalMin("0") BigDecimal carbohydrateGrams,
        @DecimalMin("0") BigDecimal fatGrams,
        @NotNull @Pattern(regexp = "UNKNOWN|PER_SERVING|PER_100G|WHOLE_RECIPE") String nutritionBasis,
        Boolean isNutritionEstimated,
        @NotNull @Min(1) @Max(100) Integer servings,
        @Min(0) @Max(1440) Integer cookingTimeMinutes,
        @Min(0) @Max(1440) Integer prepTimeMinutes,
        @Min(0) @Max(1440) Integer restingTimeMinutes,
        @Min(0) @Max(1440) Integer totalTimeMinutes,
        @Pattern(regexp = "EASY|MEDIUM|HARD|NOT_SPECIFIED") String difficulty,
        @NotEmpty @Size(max = 200) List<@NotNull @Valid IngredientInput> ingredients,
        @NotEmpty @Size(max = 200) List<@NotNull @Valid StepInput> steps,
        @NotBlank @Size(max = 10) String sourceLanguage,
        @NotBlank @Size(max = 150) String sourceName,
        @NotBlank @Size(max = 1000) String sourceUrl,
        @Size(max = 2000) String sourceImageUrl,
        @NotBlank @Size(max = 50) String scrapedAt,
        String reviewStatus,
        Boolean published,
        String translationStatus,
        String translationError,
        String translationHash,
        String glossaryVersion,
        String qaReport) {

    public record IngredientInput(
            @NotBlank @Size(max = 100) String ingredientName,
            @DecimalMin("0") @Digits(integer = 8, fraction = 2) BigDecimal quantity,
            @Size(max = 30) String unit,
            @Size(max = 150) String preparationNote,
            @Size(max = 100) String ingredientNameKm,
            @Size(max = 150) String preparationNoteKm,
            @Size(max = 2000) String originalIngredientText,
            @NotNull @Min(1) Integer displayOrder,
            @Size(max = 500) String imageUrl,
            @Size(max = 50) String imageSource,
            @Size(max = 50) String imageLicense,
            @Size(max = 30) String imageReviewStatus) {}

    public record StepInput(
            @NotNull @Min(1) Integer stepNumber,
            @NotBlank @Size(max = 255) String instruction,
            @Size(max = 4000) String instructionKm,
            @Min(0) @Max(1440) Integer durationMinutes) {}
}
