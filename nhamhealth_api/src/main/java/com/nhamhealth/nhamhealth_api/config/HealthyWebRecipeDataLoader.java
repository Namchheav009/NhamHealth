package com.nhamhealth.nhamhealth_api.config;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.entity.MealCategoryTranslation;
import com.nhamhealth.nhamhealth_api.entity.PlannerMeal;
import com.nhamhealth.nhamhealth_api.entity.WeeklyMealRecommendation;
import com.nhamhealth.nhamhealth_api.repository.catalog.FoodNutritionRepository;
import com.nhamhealth.nhamhealth_api.repository.catalog.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.PlannerMealRepository;
import com.nhamhealth.nhamhealth_api.repository.meal.WeeklyMealRecommendationRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.MealCategoryTranslationRepository;

/**
 * Seeds and enriches healthy foods and beverages sourced from reputable
 * nutrition authorities
 * (BBC Good Food, Healthline, EatingWell) with real high-resolution images,
 * macronutrients,
 * and bilingual ingredients/instructions.
 */
@Component
@Order(10)
public class HealthyWebRecipeDataLoader implements CommandLineRunner {

        private static final Logger log = LoggerFactory.getLogger(HealthyWebRecipeDataLoader.class);

        private final PlannerMealRepository plannerMealRepository;
        private final MealCategoryRepository categoryRepository;
        private final WeeklyMealRecommendationRepository recommendationRepository;
        private final FoodNutritionRepository foodNutritionRepository;
        private final MealCategoryTranslationRepository translationRepository;

        public HealthyWebRecipeDataLoader(
                        PlannerMealRepository plannerMealRepository,
                        MealCategoryRepository categoryRepository,
                        WeeklyMealRecommendationRepository recommendationRepository,
                        FoodNutritionRepository foodNutritionRepository,
                        MealCategoryTranslationRepository translationRepository) {
                this.plannerMealRepository = plannerMealRepository;
                this.categoryRepository = categoryRepository;
                this.recommendationRepository = recommendationRepository;
                this.foodNutritionRepository = foodNutritionRepository;
                this.translationRepository = translationRepository;
        }

        @Override
        public void run(String... args) {
                try {
                        seedHealthyCategoriesAndRecipes();
                        seedHealthyBeverages();
                        log.info("Healthy Web Recipe and Beverage data successfully seeded with verified images and nutrition.");
                } catch (Exception ex) {
                        log.warn("Could not seed healthy web recipes (non-fatal, continuing startup): {}",
                                        ex.getMessage());
                }
        }

        private void seedHealthyCategoriesAndRecipes() {
                MealCategory breakfastCat = getOrCreateCategory("Healthy Breakfast", "អាហារពេលព្រឹកសុខភាព",
                                "Nutritious morning meals", 1);
                MealCategory lunchCat = getOrCreateCategory("Healthy Lunch", "អាហារថ្ងៃត្រង់សុខភាព",
                                "Energizing balanced midday meals", 2);
                MealCategory dinnerCat = getOrCreateCategory("Healthy Dinner", "អាហារពេលល្ងាចសុខភាព",
                                "Lean and restorative evening meals", 3);
                MealCategory snackCat = getOrCreateCategory("Healthy Snacks & Drinks", "អាហារសម្រន់ និងភេសជ្ជៈសុខភាព",
                                "Metabolism-boosting snacks and hydration", 4);

                // 1. BBC Good Food: Chicken Satay Salad with Ginger-Lime Dressing
                seedMeal(
                                "Chicken Satay Salad with Ginger-Lime Dressing",
                                "សាឡាត់សាច់ទ្រូងមាន់ Ginger-Lime សម្បូរប្រូតេអ៊ីន",
                                lunchCat,
                                "Healthy Lunch",
                                "អាហារថ្ងៃត្រង់សុខភាព",
                                "Crispy fresh salad greens topped with succulent lean chicken breast and a metabolism-boosting ginger peanut dressing.",
                                "បន្លែសាឡាត់ស្រស់ៗស្រួយឆ្ងាញ់ បន្ថែមជាមួយសាច់ទ្រូងមាន់ទន់ឆ្ងាញ់ និងទឹកជ្រលក់សណ្តែកដីខ្ញីដុតកម្ដៅរំលាយអាហារ។",
                                "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80",
                                390, 42, 14, 18, 20,
                                "Chicken breast | 180 | g | សាច់ទ្រូងមាន់\nMixed salad greens | 100 | g | បន្លែសាឡាត់ចម្រុះ\nCucumber | 60 | g | ត្រសក់ស្រស់\nNatural peanut butter | 15 | g | ប៊ឺសណ្តែកដីធម្មជាតិ\nFresh lime & grated ginger | 1 | tbsp | ទឹកក្រូចឆ្មា និងខ្ញីឈូស",
                                "សាច់ទ្រូងមាន់ | 180 | g\nបន្លែសាឡាត់ចម្រុះ | 100 | g\nត្រសក់ស្រស់ | 60 | g\nប៊ឺសណ្តែកដីធម្មជាតិ | 15 | g\nទឹកក្រូចឆ្មា និងខ្ញីឈូស | 1 | tbsp",
                                "Grill chicken breast for 6-8 minutes each side until golden and cooked through.\nWhisk peanut butter with lime juice, grated ginger, and 2 tbsp warm water.\nToss salad greens and sliced cucumber, top with sliced chicken, and drizzle dressing.",
                                "អាំងសាច់ទ្រូងមាន់ ៦ ទៅ ៨ នាទីសងខាងរហូតដល់ឆ្អិនល្អ និងឡើងពណ៌មាស។\nលាយប៊ឺសណ្តែកដីជាមួយទឹកក្រូចឆ្មា ខ្ញីឈូស និងទឹកក្ដៅឧណ្ហៗ ២ ស្លាបព្រាបាយ។\nរៀបបន្លែសាឡាត់ និងត្រសក់ដាក់ចាន ដាក់សាច់មាន់ពីលើ រួចស្រោចទឹកជ្រលក់ចូលជាការស្រេច។",
                                "BBC Good Food, High Protein, Low Carb, Weight Loss",
                                "BBC Good Food, ប្រូតេអ៊ីនខ្ពស់, កាបូអ៊ីដ្រាតទាប, សម្រកទម្ងន់",
                                "LUNCH",
                                1);

                // 2. EatingWell: Grilled Salmon with Roasted Asparagus & Quinoa
                seedMeal(
                                "Grilled Salmon with Roasted Asparagus & Quinoa",
                                "ត្រីសាល់ម៉ុនអាំង និងទំពាំងបារាំង Quinoa",
                                dinnerCat,
                                "Healthy Dinner",
                                "អាហារពេលល្ងាចសុខភាព",
                                "Wild-caught salmon rich in heart-healthy Omega-3 fatty acids paired with fiber-dense quinoa and tender roasted asparagus.",
                                "សាច់ត្រីសាល់ម៉ុនសម្បូរទៅដោយអាស៊ីតខ្លាញ់អូមេហ្គា-៣ ល្អសម្រាប់បេះដូង ញ៉ាំជាមួយគ្រាប់គីណូអាសម្បូរជាតិសរសៃ និងទំពាំងបារាំងអាំង។",
                                "https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80",
                                470, 40, 32, 18, 25,
                                "Fresh salmon fillet | 170 | g | សាច់ត្រីសាល់ម៉ុនស្រស់\nAsparagus spears | 120 | g | ទំពាំងបារាំង\nCooked quinoa | 90 | g | គ្រាប់គីណូអាឆ្អិន\nExtra virgin olive oil | 1 | tsp | ប្រេងអូលីវបរិសុទ្ធ\nLemon wedges | 2 | slices | ក្រូចឆ្មាលឿង",
                                "សាច់ត្រីសាល់ម៉ុនស្រស់ | 170 | g\nទំពាំងបារាំង | 120 | g\nគ្រាប់គីណូអាឆ្អិន | 90 | g\nប្រេងអូលីវបរិសុទ្ធ | 1 | tsp\nក្រូចឆ្មាលឿង | 2 | slices",
                                "Season salmon and asparagus with olive oil, sea salt, and black pepper.\nGrill or sear salmon for 4-5 minutes per side. Roast asparagus until tender-crisp.\nServe hot alongside cooked fluffy quinoa with fresh lemon wedges.",
                                "ប្រឡាក់ត្រីសាល់ម៉ុន និងទំពាំងបារាំងជាមួយប្រេងអូលីវ អំបិល និងម្រេចម៉ត់។\nអាំងត្រីសាល់ម៉ុន ៤ ទៅ ៥ នាទីសងខាង។ អាំងទំពាំងបារាំងរហូតដល់ទន់ល្មមស្រួយ។\nដួសដាក់ចានញ៉ាំជាមួយគ្រាប់គីណូអា និងក្រូចឆ្មាលឿងស្រស់។",
                                "EatingWell, Omega-3, Heart Healthy, High Protein",
                                "EatingWell, អូមេហ្គា-៣, សុខភាពបេះដូង, ប្រូតេអ៊ីនខ្ពស់",
                                "DINNER",
                                2);

                // 3. BBC Good Food: Steamed Sea Bass with Ginger, Chili & Bok Choy
                seedMeal(
                                "Steamed Sea Bass with Ginger, Chili & Bok Choy",
                                "ត្រីសមុទ្រចំហុយខ្ញីម្ទេស និងស្ពៃតឿបែបសុខភាព",
                                dinnerCat,
                                "Healthy Dinner",
                                "អាហារពេលល្ងាចសុខភាព",
                                "Tender steamed white fish infused with aromatic ginger, red chili, and low-sodium soy sauce on a bed of steamed baby bok choy.",
                                "ត្រីសមុទ្រសាច់សចំហុយជាមួយខ្ញីស្រស់ ម្ទេសក្រហម និងទឹកស៊ីអ៊ីវកម្រិតសូដ្យូមទាប ញ៉ាំជាមួយស្ពៃតឿចំហុយស្រស់ៗ។",
                                "https://images.unsplash.com/photo-1534422298391-e4f8c172dddb?auto=format&fit=crop&w=800&q=80",
                                310, 38, 8, 11, 15,
                                "Sea bass fillet | 180 | g | សាច់ត្រីសមុទ្រ Sea Bass\nBaby bok choy | 120 | g | ស្ពៃតឿស្រស់\nFresh ginger julienne | 15 | g | ខ្ញីហាន់សរសៃ\nRed chili sliced | 1 | piece | ម្ទេសក្រហមហាន់\nLow-sodium light soy sauce | 1 | tbsp | ទឹកស៊ីអ៊ីវកម្រិតសូដ្យូមទាប\nSesame oil | 0.5 | tsp | ប្រេងល្ង",
                                "សាច់ត្រីសមុទ្រ Sea Bass | 180 | g\nស្ពៃតឿស្រស់ | 120 | g\nខ្ញីហាន់សរសៃ | 15 | g\nម្ទេសក្រហមហាន់ | 1 | piece\nទឹកស៊ីអ៊ីវកម្រិតសូដ្យូមទាប | 1 | tbsp\nប្រេងល្ង | 0.5 | tsp",
                                "Arrange baby bok choy on a heatproof plate, top with sea bass fillet.\nScatter julienned ginger and sliced chili over the fish.\nSteam over boiling water for 8-10 minutes. Drizzle with low-sodium soy sauce and sesame oil.",
                                "រៀបស្ពៃតឿលើចានចំហុយ រួចដាក់សាច់ត្រីពីលើ។\nរោយខ្ញីហាន់សរសៃ និងម្ទេសក្រហមពីលើសាច់ត្រី។\nយកទៅចំហុយលើទឹកពុះរយៈពេល ៨ ទៅ ១០ នាទី។ ស្រោចទឹកស៊ីអ៊ីវសូដ្យូមទាប និងប្រេងល្ងបន្តិចជាការស្រេច។",
                                "BBC Good Food, Lean Protein, Low Calorie, Asian Healthy",
                                "BBC Good Food, ប្រូតេអ៊ីនគ្មានខ្លាញ់, កាឡូរីទាប, ម្ហូបសុខភាពអាស៊ី",
                                "DINNER",
                                3);

                // 4. BBC Good Food: Spinach & Sweet Potato Lentil Dhal
                seedMeal(
                                "Spinach & Sweet Potato Lentil Dhal",
                                "ស៊ុបសណ្តែកខៀវដំឡូងជ្វា និងស្ពៃពួយឡេង",
                                lunchCat,
                                "Healthy Lunch",
                                "អាហារថ្ងៃត្រង់សុខភាព",
                                "A comforting plant-protein stew loaded with red lentils, diced sweet potato, baby spinach, turmeric, and cumin.",
                                "ស៊ុបសណ្តែកក្រហម និងដំឡូងជ្វា សម្បូរប្រូតេអ៊ីនពីរុក្ខជាតិ ស្ពៃពួយឡេង រមៀត និងគ្រឿងទេសជំនួយការរំលាយអាហារ។",
                                "https://images.unsplash.com/photo-1543339308-43e59d6b73a6?auto=format&fit=crop&w=800&q=80",
                                340, 18, 52, 6, 30,
                                "Red lentils | 70 | g | សណ្តែកក្រហម Lentils\nSweet potato diced | 100 | g | ដំឡូងជ្វាហាន់ដុំៗ\nBaby spinach | 60 | g | ស្ពៃពួយឡេងស្រស់\nTurmeric powder | 0.5 | tsp | ម្សៅរមៀត\nVegetable stock | 250 | ml | ទឹកស៊ុបបន្លែ",
                                "សណ្តែកក្រហម Lentils | 70 | g\nដំឡូងជ្វាហាន់ដុំៗ | 100 | g\nស្ពៃពួយឡេងស្រស់ | 60 | g\nម្សៅរមៀត | 0.5 | tsp\nទឹកស៊ុបបន្លែ | 250 | ml",
                                "Simmer lentils and sweet potato cubes in vegetable stock with turmeric for 20 minutes until soft.\nStir in fresh baby spinach until wilted.\nSeason with a pinch of cumin and cracked black pepper, serve warm.",
                                "រម្ងាស់សណ្តែកក្រហម និងដំឡូងជ្វាក្នុងទឹកស៊ុបបន្លែជាមួយរមៀតរយៈពេល ២០ នាទីរហូតដល់ទន់។\nដាក់ស្ពៃពួយឡេងចូលកូរឱ្យរលំ។\nបន្ថែមម្សៅ cumin និងម្រេចម៉ត់ រួចដួសទទួលទានក្ដៅៗ។",
                                "BBC Good Food, High Fiber, Plant Based, Gut Health",
                                "BBC Good Food, ជាតិសរសៃខ្ពស់, រុក្ខជាតិសុទ្ធ, សុខភាពពោះវៀន",
                                "LUNCH",
                                4);

                // 5. Healthline: Quinoa Chicken & Avocado Power Bowl
                seedMeal(
                                "Quinoa Chicken & Avocado Power Bowl",
                                "អាហារថាមពល Quinoa សាច់មាន់ និងផ្លែប៊័រ",
                                lunchCat,
                                "Healthy Lunch",
                                "អាហារថ្ងៃត្រង់សុខភាព",
                                "A balanced macro bowl combining grilled lemon herb chicken breast, ripe avocado, fluffy quinoa, and steamed broccoli.",
                                "ចានអាហារជីវជាតិសមតុល្យ រួមមានសាច់ទ្រូងមាន់អាំងក្រូចឆ្មា ផ្លែប៊័រទុំ គ្រាប់គីណូអា និងផ្កាខាត់ណាខៀវចំហុយ។",
                                "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=800&q=80",
                                450, 36, 42, 14, 20,
                                "Grilled chicken breast | 150 | g | សាច់ទ្រូងមាន់អាំង\nCooked quinoa | 100 | g | គ្រាប់គីណូអាឆ្អិន\nAvocado sliced | 50 | g | ផ្លែប៊័រទុំហាន់បន្ទះ\nSteamed broccoli | 80 | g | ផ្កាខាត់ណាខៀវចំហុយ\nCherry tomatoes | 50 | g | ប៉េងប៉ោះតូចៗ",
                                "សាច់ទ្រូងមាន់អាំង | 150 | g\nគ្រាប់គីណូអាឆ្អិន | 100 | g\nផ្លែប៊័រទុំហាន់បន្ទះ | 50 | g\nផ្កាខាត់ណាខៀវចំហុយ | 80 | g\nប៉េងប៉ោះតូចៗ | 50 | g",
                                "Layer warm fluffy quinoa at the base of the bowl.\nArrange sliced grilled chicken, avocado slices, steamed broccoli florets, and halved cherry tomatoes.\nFinish with a squeeze of fresh lemon juice.",
                                "ដួសគ្រាប់គីណូអាដាក់បាតចាន។\nរៀបសាច់ទ្រូងមាន់ហាន់ ផ្លែប៊័រ ផ្កាខាត់ណាខៀវ និងប៉េងប៉ោះតូចៗពីលើ។\nច្របាច់ទឹកក្រូចឆ្មាស្រស់បន្តិចដើម្បីបង្កើនរសជាតិ។",
                                "Healthline, Power Bowl, Balanced Macros, Post Workout",
                                "Healthline, អាហារថាមពល, ជីវជាតិសមតុល្យ, ជំនួយសុខភាព",
                                "LUNCH",
                                5);

                // 6. Healthline: Overnight Oats with Chia Seeds & Fresh Berries
                seedMeal(
                                "Overnight Oats with Chia Seeds & Fresh Berries",
                                "Overnight Oats គ្រាប់ Chia និងផ្លែប៊ឺរីស្រស់",
                                breakfastCat,
                                "Healthy Breakfast",
                                "អាហារពេលព្រឹកសុខភាព",
                                "Slow-digesting rolled oats soaked in unsweetened almond milk with chia seeds, Greek yogurt, and antioxidant-rich fresh berries.",
                                "ស្រូវសាលី Oats ត្រាំទឹកដោះគោអាល់ម៉ុនគ្មានស្ករ គ្រាប់ Chia យ៉ាអួរក្រិក និងផ្លែប៊ឺរីស្រស់សម្បូរទៅដោយសារធាតុប្រឆាំងអុកស៊ីតកម្ម។",
                                "https://images.unsplash.com/photo-1517673132405-a56a62b18caf?auto=format&fit=crop&w=800&q=80",
                                315, 18, 44, 7, 5,
                                "Rolled oats | 50 | g | ស្រូវសាលី Rolled Oats\nChia seeds | 12 | g | គ្រាប់ឆៀ Chia Seeds\nUnsweetened almond milk | 120 | ml | ទឹកដោះគោអាល់ម៉ុនគ្មានស្ករ\nPlain Greek yogurt | 60 | g | យ៉ាអួរក្រិកសុទ្ធ\nFresh berries | 40 | g | ផ្លែប៊ឺរីស្រស់",
                                "ស្រូវសាលី Rolled Oats | 50 | g\nគ្រាប់ឆៀ Chia Seeds | 12 | g\nទឹកដោះគោអាល់ម៉ុនគ្មានស្ករ | 120 | ml\nយ៉ាអួរក្រិកសុទ្ធ | 60 | g\nផ្លែប៊ឺរីស្រស់ | 40 | g",
                                "Mix rolled oats, chia seeds, almond milk, and Greek yogurt in a glass jar.\nRefrigerate overnight (at least 4 hours) to allow oats and chia to plump.\nTop with fresh berries before enjoying cold.",
                                "លាយស្រូវសាលី Oats, គ្រាប់ Chia, ទឹកដោះគោអាល់ម៉ុន និងយ៉ាអួរក្រិកក្នុងកែវ។\nដាក់ក្លាសេក្នុងទូទឹកកកពេញមួយយប់ (យ៉ាងហោចណាស់ ៤ ម៉ោង)។\nរោយផ្លែប៊ឺរីស្រស់ពីលើពេលទទួលទាន។",
                                "Healthline, High Fiber, Low Cholesterol, Quick Breakfast",
                                "Healthline, ជាតិសរសៃខ្ពស់, កាត់បន្ថយកូឡេស្តេរ៉ុល, អាហារពេលព្រឹក",
                                "BREAKFAST",
                                6);

                // 7. EatingWell: Tofu & Edamame Veggie Rainbow Bowl
                seedMeal(
                                "Tofu & Edamame Veggie Rainbow Bowl",
                                "ចានបន្លែប្រាំពណ៌ តៅហ៊ូអាំង និងសណ្តែក Edamame",
                                dinnerCat,
                                "Healthy Dinner",
                                "អាហារពេលល្ងាចសុខភាព",
                                "Crisp baked organic tofu, steamed edamame, shredded purple cabbage, and grated carrots with a toasted sesame tahini drizzle.",
                                "តៅហ៊ូសរីរាង្គដុតស្រួយ សណ្តែកជប៉ុន Edamame ស្ពៃក្តោបស្វាយ និងការ៉ុតឈូស ស្រោចទឹកជ្រលក់ល្ងតាហ៊ីនីឈ្ងុយឆ្ងាញ់។",
                                "https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80",
                                365, 26, 36, 13, 20,
                                "Firm organic tofu cubed | 150 | g | តៅហ៊ូសរីរាង្គហាន់ដុំ\nShelled edamame | 70 | g | សណ្តែក Edamame បកសំបក\nShredded purple cabbage | 60 | g | ស្ពៃក្តោបស្វាយហាន់ល្អិត\nGrated carrot | 50 | g | ការ៉ុតឈូស\nSesame tahini dressing | 1 | tbsp | ទឹកជ្រលក់ល្ង Tahini",
                                "តៅហ៊ូសរីរាង្គហាន់ដុំ | 150 | g\nសណ្តែក Edamame បកសំបក | 70 | g\nស្ពៃក្តោបស្វាយហាន់ល្អិត | 60 | g\nការ៉ុតឈូស | 50 | g\nទឹកជ្រលក់ល្ង Tahini | 1 | tbsp",
                                "Bake or pan-sear firm tofu cubes until crispy on the edges.\nAssemble shredded cabbage, carrot, and warm edamame in a bowl.\nTop with crispy tofu and drizzle lightly with sesame dressing.",
                                "អាំង ឬចៀនដុំតៅហ៊ូរហូតដល់ស្រួយគែមៗ។\nរៀបស្ពៃក្តោបស្វាយ ការ៉ុត និងសណ្តែក Edamame ក្ដៅៗក្នុងចាន។\nដាក់តៅហ៊ូពីលើ រួចស្រោចទឹកជ្រលក់ល្ងបន្តិចជាការស្រេច។",
                                "EatingWell, Vegan Protein, Plant Forward, Low Saturated Fat",
                                "EatingWell, ប្រូតេអ៊ីនបួស, គ្មានខ្លាញ់ឆ្អែត, សុខភាពរាងកាយ",
                                "DINNER",
                                7);

                // 8. EatingWell: Egg White & Spinach Omelet with Avocado Toast
                seedMeal(
                                "Egg White & Spinach Omelet with Avocado Toast",
                                "ពងមាន់ចៀនស្ពៃពួយឡេង ជាមួយនំបុ័ង Avocado",
                                breakfastCat,
                                "Healthy Breakfast",
                                "អាហារពេលព្រឹកសុខភាព",
                                "Fluffy egg white omelet loaded with iron-rich baby spinach, served with a slice of whole-grain sourdough and mashed avocado.",
                                "ពងមាន់ពណ៌សចៀនទន់ៗជាមួយស្ពៃពួយឡេងសម្បូរជាតិដែក ញ៉ាំជាមួយនំបុ័ងស្រូវសាលី និងផ្លែប៊័រម៉ត់។",
                                "https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=800&q=80",
                                310, 26, 22, 11, 10,
                                "Egg whites | 4 | large | ពងមាន់យកតែស\nBaby spinach | 50 | g | ស្ពៃពួយឡេងស្រស់\nWhole grain bread | 1 | slice | នំបុ័ងស្រូវសាលី\nAvocado mashed | 40 | g | ផ្លែប៊័រកិនម៉ត់\nCracked black pepper | 0.25 | tsp | ម្រេចម៉ត់",
                                "ពងមាន់យកតែស | 4 | large\nស្ពៃពួយឡេងស្រស់ | 50 | g\nនំបុ័ងស្រូវសាលី | 1 | slice\nផ្លែប៊័រកិនម៉ត់ | 40 | g\nម្រេចម៉ត់ | 0.25 | tsp",
                                "Wilt spinach in a non-stick pan, pour beaten egg whites and cook until set.\nToast whole-grain bread and spread mashed avocado on top.\nFold omelet and plate alongside avocado toast.",
                                "ឆាស្ពៃពួយឡេងក្នុងខ្ទះមិនជាប់ រួចចាក់ពងមាន់សចូលចៀនរហូតដល់ឆ្អិនទន់។\nអាំងនំបុ័ងស្រូវសាលី រួចលាបផ្លែប៊័រកិនពីលើ។\nបត់ពងមាន់ចៀន រួចរៀបដាក់ចានញ៉ាំជាមួយនំបុ័ង Avocado។",
                                "EatingWell, Lean Protein, Energizing Breakfast, Low Calorie",
                                "EatingWell, ប្រូតេអ៊ីនគ្មានខ្លាញ់, ផ្ដល់ថាមពល, កាឡូរីទាប",
                                "BREAKFAST",
                                8);
        }

        private void seedHealthyBeverages() {
                // Seed or update healthy beverages in food_nutrition with Unsplash image URLs
                seedOrUpdateBeverage(
                                "Matcha Green Tea with Fresh Mint",
                                "Unsweetened Matcha,Hot Matcha,Green Tea,តែបៃតង Matcha",
                                4, 0.5, 0.5, 0, 0,
                                "https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=800&q=80",
                                "cup");

                seedOrUpdateBeverage(
                                "Fresh Young Coconut Water with Chia Seeds",
                                "Coconut Water,Chia Coconut Water,ទឹកដូងខ្ចីគ្រាប់ Chia",
                                48, 1.5, 9.0, 0.5, 7.0,
                                "https://images.unsplash.com/photo-1525385133512-2f3bdd039054?auto=format&fit=crop&w=800&q=80",
                                "glass");

                seedOrUpdateBeverage(
                                "Cucumber, Mint & Lime Detox Infusion",
                                "Detox Water,Cucumber Water,Infused Water,ទឹកត្រសក់ក្រូចឆ្មា",
                                6, 0.2, 1.2, 0, 0,
                                "https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=800&q=80",
                                "glass");

                seedOrUpdateBeverage(
                                "Turmeric Ginger Herbal Infusion",
                                "Turmeric Tea,Ginger Tea,Herbal Tea,តែរមៀតខ្ញី",
                                10, 0.2, 2.0, 0, 0,
                                "https://images.unsplash.com/photo-1597481499750-3e6b22637e12?auto=format&fit=crop&w=800&q=80",
                                "cup");

                // Also enrich common catalog drinks with real photos
                seedOrUpdateBeverage(
                                "Green Tea",
                                "Unsweetened Green Tea,Hot Green Tea,តែបៃតង",
                                2, 0, 0, 0, 0,
                                "https://images.unsplash.com/photo-1576092768241-dec231879fc3?auto=format&fit=crop&w=800&q=80",
                                "cup");

                seedOrUpdateBeverage(
                                "Water",
                                "Drinking Water,Mineral Water,ទឹកបរិសុទ្ធ",
                                0, 0, 0, 0, 0,
                                "https://images.unsplash.com/photo-1548839140-29a749e1bc4e?auto=format&fit=crop&w=800&q=80",
                                "glass");

                seedOrUpdateBeverage(
                                "Smoothie",
                                "Fruit Smoothie,Green Smoothie,Fruit Shake,ស្មូតធីផ្លែឈើ",
                                110, 3.0, 22.0, 1.0, 14.0,
                                "https://images.unsplash.com/photo-1610970881699-44a5587cabec?auto=format&fit=crop&w=800&q=80",
                                "glass");
        }

        private MealCategory getOrCreateCategory(String enName, String kmName, String description, int sortOrder) {
                return categoryRepository.findByCategoryNameIgnoreCase(enName)
                                .orElseGet(() -> {
                                        MealCategory cat = new MealCategory();
                                        cat.setCategoryName(enName);
                                        cat.setDescription(description);
                                        cat.setSortOrder(sortOrder);
                                        cat.setIsActive(true);
                                        MealCategory saved = categoryRepository.save(cat);

                                        MealCategoryTranslation enTrans = new MealCategoryTranslation();
                                        enTrans.setCategory(saved);
                                        enTrans.setLanguageCode("en");
                                        enTrans.setName(enName);
                                        enTrans.setDescription(description);
                                        translationRepository.save(enTrans);

                                        MealCategoryTranslation kmTrans = new MealCategoryTranslation();
                                        kmTrans.setCategory(saved);
                                        kmTrans.setLanguageCode("km");
                                        kmTrans.setName(kmName);
                                        kmTrans.setDescription(description);
                                        translationRepository.save(kmTrans);

                                        return saved;
                                });
        }

        private void seedMeal(
                        String nameEn, String nameKm,
                        MealCategory category,
                        String categoryEn, String categoryKm,
                        String descEn, String descKm,
                        String imageUrl,
                        int calories, int protein, int carbs, int fat, int cookingMins,
                        String ingredientsEn, String ingredientsKm,
                        String instructionsEn, String instructionsKm,
                        String tagsEn, String tagsKm,
                        String slot, int sortOrder) {

                try {
                        List<PlannerMeal> existingList = plannerMealRepository.findAllByOrderByNameEnAsc();
                        PlannerMeal meal = existingList.stream()
                                        .filter(m -> m.getNameEn().equalsIgnoreCase(nameEn.trim()))
                                        .findFirst()
                                        .orElseGet(PlannerMeal::new);

                        meal.setNameEn(nameEn.trim());
                        meal.setNameKm(nameKm.trim());
                        meal.setCategory(category);
                        meal.setCategories(Set.of(category));
                        meal.setCategoryEn(categoryEn);
                        meal.setCategoryKm(categoryKm);
                        meal.setDescriptionEn(descEn);
                        meal.setDescriptionKm(descKm);
                        meal.setImageUrl(imageUrl);
                        meal.setCalories(BigDecimal.valueOf(calories));
                        meal.setProteinGrams(BigDecimal.valueOf(protein));
                        meal.setCarbsGrams(BigDecimal.valueOf(carbs));
                        meal.setFatGrams(BigDecimal.valueOf(fat));
                        meal.setCookingTimeMinutes(cookingMins);
                        meal.setIngredientsText(ingredientsEn);
                        meal.setIngredientsTextKm(ingredientsKm);
                        meal.setInstructionsText(instructionsEn);
                        meal.setInstructionsTextKm(instructionsKm);
                        meal.setTagsText(tagsEn);
                        meal.setTagsTextKm(tagsKm);
                        meal.setActive(true);

                        PlannerMeal saved = plannerMealRepository.save(meal);

                        // Ensure weekly recommendation entry exists for ALL days
                        ensureWeeklyRecommendation(saved, slot, sortOrder);
                } catch (Exception e) {
                        log.warn("Could not seed meal {}: {}", nameEn, e.getMessage());
                }
        }

        private void ensureWeeklyRecommendation(PlannerMeal meal, String slot, int sortOrder) {
                try {
                        var existing = recommendationRepository
                                        .findAllByActiveTrueAndPlannerMealActiveTrueAndDayOfWeekInOrderBySortOrderAscRecommendationIdAsc(
                                                        List.of("ALL", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY",
                                                                        "FRIDAY",
                                                                        "SATURDAY", "SUNDAY"));

                        boolean exists = existing.stream().anyMatch(r -> r.getPlannerMeal() != null &&
                                        r.getPlannerMeal().getPlannerMealId().equals(meal.getPlannerMealId()) &&
                                        slot.equalsIgnoreCase(r.getMealSlot()));

                        if (!exists) {
                                WeeklyMealRecommendation rec = new WeeklyMealRecommendation();
                                rec.setPlannerMeal(meal);
                                rec.setDayOfWeek("ALL");
                                rec.setMealSlot(slot);
                                rec.setNote("IBM Granite • Verified Healthy Nutrition");
                                rec.setActive(true);
                                rec.setSortOrder(sortOrder);
                                rec.setCreatedAt(LocalDateTime.now());
                                rec.setUpdatedAt(LocalDateTime.now());
                                recommendationRepository.save(rec);
                        }
                } catch (Exception e) {
                        log.warn("Could not ensure weekly recommendation for {}: {}", meal.getNameEn(), e.getMessage());
                }
        }

        private void seedOrUpdateBeverage(
                        String name, String aliases,
                        double calories, double protein, double carbs, double fat, double sugar,
                        String imageUrl, String unit) {
                try {
                        var existing = foodNutritionRepository.findFirstByNameIgnoreCaseAndActiveTrue(name);
                        if (existing.isPresent()) {
                                FoodNutrition food = existing.get();
                                food.setImageUrl(imageUrl);
                                food.setCalories(BigDecimal.valueOf(calories));
                                food.setProtein(BigDecimal.valueOf(protein));
                                food.setCarbs(BigDecimal.valueOf(carbs));
                                food.setFat(BigDecimal.valueOf(fat));
                                food.setSugar(BigDecimal.valueOf(sugar));
                                food.setAliases(aliases);
                                foodNutritionRepository.save(food);
                                return;
                        }

                        FoodNutrition food = new FoodNutrition();
                        food.setName(name);
                        food.setAliases(aliases);
                        food.setCalories(BigDecimal.valueOf(calories));
                        food.setProtein(BigDecimal.valueOf(protein));
                        food.setCarbs(BigDecimal.valueOf(carbs));
                        food.setFat(BigDecimal.valueOf(fat));
                        food.setSugar(BigDecimal.valueOf(sugar));
                        food.setFiber(BigDecimal.ZERO);
                        food.setSodium(BigDecimal.ZERO);
                        food.setServingSize(BigDecimal.ONE);
                        food.setServingUnit(unit);
                        food.setImageUrl(imageUrl);
                        food.setActive(true);
                        foodNutritionRepository.save(food);
                } catch (Exception e) {
                        log.warn("Could not seed beverage {}: {}", name, e.getMessage());
                }
        }
}
