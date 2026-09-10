package com.nhamhealth.nhamhealth_api.dto.response;
import java.math.BigDecimal; import java.util.List;
public record MealDetailResponse(Integer id,String languageCode,String name,Integer categoryId,String category,String imageUrl,BigDecimal calories,String description,Integer cookingTimeMinutes,String difficulty,Integer servings,List<IngredientItem> ingredients,List<NutritionItem> nutrition,List<StepItem> steps,List<LabelItem> tags,List<LabelItem> moods){
 public record IngredientItem(Integer id,String name,String description,String imageUrl,BigDecimal quantity,String unit,String preparationNote){}
 public record NutritionItem(String name,BigDecimal amount,String unit){}
 public record StepItem(Integer number,String instruction){}
 public record LabelItem(Integer id,String name){}
}
