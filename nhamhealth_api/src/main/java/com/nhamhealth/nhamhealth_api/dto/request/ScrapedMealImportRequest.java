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
        @NotNull(message = "calories is required") @DecimalMin(value = "0", message = "calories must be non-negative") BigDecimal calories,
        @NotNull(message = "proteinGrams is required") @DecimalMin(value = "0", message = "proteinGrams must be non-negative") BigDecimal proteinGrams,
        @DecimalMin("0") BigDecimal carbohydrateGrams,
        @DecimalMin("0") BigDecimal fatGrams,
        @NotNull @Pattern(regexp = "UNKNOWN|PER_SERVING|PER_100G|WHOLE_RECIPE") String nutritionBasis,
        @NotNull @Min(1) @Max(100) Integer servings,
        @Min(0) @Max(1440) Integer cookingTimeMinutes,
        @Pattern(regexp = "EASY|MEDIUM|HARD|NOT_SPECIFIED") String difficulty,
        @NotEmpty @Size(max = 200) List<@NotNull @Valid IngredientInput> ingredients,
        @NotEmpty @Size(max = 200) List<@NotNull @Valid StepInput> steps,
        @NotBlank @Size(max = 10) String sourceLanguage,
        @NotBlank @Size(max = 150) String sourceName,
        @NotBlank @Size(max = 1000) String sourceUrl,
        @Size(max = 2000) String sourceImageUrl,
        @NotBlank @Size(max = 50) String scrapedAt,
        String reviewStatus,
        Boolean published) {

    public record IngredientInput(
            @NotBlank @Size(max = 100) String ingredientName,
            @DecimalMin("0") @Digits(integer = 8, fraction = 2) BigDecimal quantity,
            @Size(max = 30) String unit,
            @Size(max = 150) String preparationNote,
            @Size(max = 100) String ingredientNameKm,
            @Size(max = 150) String preparationNoteKm,
            @Size(max = 2000) String originalIngredientText,
            @NotNull @Min(1) Integer displayOrder) {}

    public record StepInput(
            @NotNull @Min(1) Integer stepNumber,
            @NotBlank @Size(max = 255) String instruction,
            @Size(max = 4000) String instructionKm) {}
}
