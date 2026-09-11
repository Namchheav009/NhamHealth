package com.nhamhealth.nhamhealth_api.service.meal;
import java.util.*; import java.util.function.Function; import java.util.stream.Collectors;
import org.springframework.stereotype.Service; import org.springframework.transaction.annotation.Transactional;
import com.nhamhealth.nhamhealth_api.dto.response.MealDetailResponse; import com.nhamhealth.nhamhealth_api.dto.response.MealResponse; import com.nhamhealth.nhamhealth_api.entity.*;
import com.nhamhealth.nhamhealth_api.repository.meal.*; import com.nhamhealth.nhamhealth_api.repository.recipe.RecipeStepRepository; import com.nhamhealth.nhamhealth_api.repository.translation.*;
@Service public class MealTranslationService {
 private final MealRepository meals; private final MealIngredientRepository ingredients; private final MealNutritionRepository nutrition; private final RecipeStepRepository steps; private final MealTagRepository mealTags; private final MealMoodRepository mealMoods; private final MealTranslationRepository mealTranslations; private final IngredientTranslationRepository ingredientTranslations; private final MealIngredientTranslationRepository noteTranslations; private final RecipeStepTranslationRepository stepTranslations; private final MealCategoryTranslationRepository categoryTranslations; private final TagTranslationRepository tagTranslations; private final MoodTranslationRepository moodTranslations;
 public MealTranslationService(MealRepository a,MealIngredientRepository b,MealNutritionRepository c,RecipeStepRepository d,MealTagRepository e,MealMoodRepository f,MealTranslationRepository g,IngredientTranslationRepository h,MealIngredientTranslationRepository i,RecipeStepTranslationRepository j,MealCategoryTranslationRepository k,TagTranslationRepository l,MoodTranslationRepository m){meals=a;ingredients=b;nutrition=c;steps=d;mealTags=e;mealMoods=f;mealTranslations=g;ingredientTranslations=h;noteTranslations=i;stepTranslations=j;categoryTranslations=k;tagTranslations=l;moodTranslations=m;}
 @Transactional(readOnly=true) public Optional<MealDetailResponse> detail(Integer id,String requested){String lang=normalizeLanguage(requested);return meals.findById(id).filter(x->Boolean.TRUE.equals(x.getIsPublished())).map(x->localize(x,lang));}

 @Transactional(readOnly=true)
 public List<MealResponse> publishedMeals(List<Meal> mealList, String requested) {
  String lang = normalizeLanguage(requested);
  if ("en".equals(lang) || mealList.isEmpty()) {
   return mealList.stream().map(MealResponse::from).toList();
  }
  List<Integer> mealIds = mealList.stream().map(Meal::getMealId).toList();
  Map<Integer, MealTranslation> transMap = mealTranslations
    .findByMealMealIdInAndLanguageCode(mealIds, lang)
    .stream()
    .collect(Collectors.toMap(t -> t.getMeal().getMealId(), Function.identity(), (a, b) -> a));
  Map<Integer, MealCategoryTranslation> catMap = categoryTranslations
    .findByLanguageCode(lang)
    .stream()
    .collect(Collectors.toMap(c -> c.getCategory().getCategoryId(), Function.identity(), (a, b) -> a));

  return mealList.stream().map(m -> {
   MealTranslation mt = transMap.get(m.getMealId());
   MealCategory cat = m.getCategory();
   MealCategoryTranslation ct = cat == null ? null : catMap.get(cat.getCategoryId());
   String catName = ct != null && ct.getName() != null && !ct.getName().isBlank()
     ? ct.getName()
     : (cat == null ? "Uncategorized" : cat.getCategoryName());
   String name = mt != null && mt.getMealName() != null && !mt.getMealName().isBlank()
     ? mt.getMealName()
     : m.getMealName();
   String desc = mt != null && mt.getDescription() != null && !mt.getDescription().isBlank()
     ? mt.getDescription()
     : m.getDescription();
   return new MealResponse(
     m.getMealId(),
     name,
     cat == null ? null : cat.getCategoryId(),
     catName,
     m.getMainImageUrl(),
     m.getCaloriesCached(),
     m.getProteinGramsCached(),
     desc,
     m.getCookingTimeMinutes(),
     m.getDifficulty(),
     m.getServings());
  }).toList();
 }
 private MealDetailResponse localize(Meal meal,String lang){
  var ingredientRows=ingredients.findByMealMealIdOrderByDisplayOrderAsc(meal.getMealId()); var stepRows=steps.findByMealMealIdOrderByStepNumberAsc(meal.getMealId()); var tagRows=mealTags.findByMealMealId(meal.getMealId()); var moodRows=mealMoods.findByMealMealId(meal.getMealId()); var mt=mealTranslations.findByMealMealIdAndLanguageCode(meal.getMealId(),lang).orElse(null);
  var it=index(ingredientTranslations.findByIngredientIngredientIdInAndLanguageCode(ingredientRows.stream().map(x->x.getIngredient().getIngredientId()).toList(),lang),x->x.getIngredient().getIngredientId()); var nt=index(noteTranslations.findByMealIngredientMealIngredientIdInAndLanguageCode(ingredientRows.stream().map(MealIngredient::getMealIngredientId).toList(),lang),x->x.getMealIngredient().getMealIngredientId()); var st=index(stepTranslations.findByRecipeStepStepIdInAndLanguageCode(stepRows.stream().map(RecipeStep::getStepId).toList(),lang),x->x.getRecipeStep().getStepId()); var tt=index(tagTranslations.findByTagTagIdInAndLanguageCode(tagRows.stream().map(x->x.getTag().getTagId()).toList(),lang),x->x.getTag().getTagId()); var mot=index(moodTranslations.findByMoodMoodIdInAndLanguageCode(moodRows.stream().map(x->x.getMood().getMoodId()).toList(),lang),x->x.getMood().getMoodId());
  MealCategory category=meal.getCategory(); var ct=category==null?null:categoryTranslations.findByCategoryCategoryIdAndLanguageCode(category.getCategoryId(),lang).orElse(null);
  return new MealDetailResponse(meal.getMealId(),lang,prefer(mt==null?null:mt.getMealName(),meal.getMealName()),category==null?null:category.getCategoryId(),prefer(ct==null?null:ct.getName(),category==null?"Uncategorized":category.getCategoryName()),meal.getMainImageUrl(),meal.getCaloriesCached(),prefer(mt==null?null:mt.getDescription(),meal.getDescription()),meal.getCookingTimeMinutes(),meal.getDifficulty(),meal.getServings(),ingredientRows.stream().map(x->{var t=it.get(x.getIngredient().getIngredientId());var n=nt.get(x.getMealIngredientId());return new MealDetailResponse.IngredientItem(x.getIngredient().getIngredientId(),prefer(t==null?null:t.getName(),x.getIngredient().getIngredientName()),cleanIngredientDescription(prefer(t==null?null:t.getDescription(),x.getIngredient().getDescription())),x.getIngredient().getImageUrl(),x.getQuantity(),x.getUnit(),prefer(n==null?null:n.getPreparationNote(),x.getPreparationNote()));}).toList(),nutrition.findByMealMealIdOrderByNutrientDisplayOrderAsc(meal.getMealId()).stream().map(x->new MealDetailResponse.NutritionItem(x.getNutrient().getNutrientName(),x.getAmountPerServing(),x.getNutrient().getUnit())).toList(),stepRows.stream().map(x->new MealDetailResponse.StepItem(x.getStepNumber(),prefer(st.get(x.getStepId())==null?null:st.get(x.getStepId()).getInstruction(),x.getInstruction()))).toList(),tagRows.stream().map(x->new MealDetailResponse.LabelItem(x.getTag().getTagId(),prefer(tt.get(x.getTag().getTagId())==null?null:tt.get(x.getTag().getTagId()).getName(),x.getTag().getTagName()))).toList(),moodRows.stream().map(x->new MealDetailResponse.LabelItem(x.getMood().getMoodId(),prefer(mot.get(x.getMood().getMoodId())==null?null:mot.get(x.getMood().getMoodId()).getName(),x.getMood().getMoodName()))).toList());
 }
 public static String normalizeLanguage(String v){return "km".equalsIgnoreCase(v==null?"":v.trim())?"km":"en";} private static String prefer(String a,String b){return a==null||a.isBlank()?(b==null?"":b):a;} private static <T> Map<Integer,T> index(List<T> rows,Function<T,Integer> key){return rows.stream().collect(Collectors.toMap(key,Function.identity()));}
 private static String cleanIngredientDescription(String s){if(s==null||s.isBlank()||s.startsWith("Auto-created")||s.contains("scraped recipe source"))return "";return s.trim();}
}
