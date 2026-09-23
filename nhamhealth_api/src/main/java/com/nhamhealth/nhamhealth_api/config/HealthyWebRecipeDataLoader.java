package com.nhamhealth.nhamhealth_api.config;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.repository.catalog.FoodNutritionRepository;

/**
 * Seeds and enriches healthy beverage catalog entries.
 */
@Component
@Order(10)
public class HealthyWebRecipeDataLoader implements CommandLineRunner {

        private static final Logger log = LoggerFactory.getLogger(HealthyWebRecipeDataLoader.class);

        private final FoodNutritionRepository foodNutritionRepository;

        public HealthyWebRecipeDataLoader(FoodNutritionRepository foodNutritionRepository) {
                this.foodNutritionRepository = foodNutritionRepository;
        }

        @Override
        public void run(String... args) {
                try {
                        seedHealthyBeverages();
                        log.info("Healthy beverage data seeded.");
                } catch (Exception ex) {
                        log.warn("Could not seed healthy web recipes (non-fatal, continuing startup): {}",
                                        ex.getMessage());
                }
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
