package com.nhamhealth.nhamhealth_api.config;

import java.math.BigDecimal;
import java.util.List;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.repository.FoodNutritionRepository;

/**
 * Adds a baseline catalog without replacing administrator-managed nutrition data.
 * Values are approximate examples and are not medical-grade nutrition data.
 */
@Component
public class DevFoodNutritionDataLoader implements CommandLineRunner {
    private final FoodNutritionRepository repository;
    public DevFoodNutritionDataLoader(FoodNutritionRepository repository) { this.repository = repository; }

    @Override
    @Transactional
    public void run(String... args) {
        seed("Bai Sach Chrouk", "Pork Rice,Rice with Pork,Grilled Pork Rice,បាយសាច់ជ្រូក", 500, 25, 65, 16, 5, "plate");
        seed("Num Banh Chok", "Khmer Noodles,Nom Banh Chok,នំបញ្ចុក", 380, 14, 62, 9, 7, "bowl");
        seed("Fish Amok", "Amok Trey,Khmer Fish Curry,អាម៉ុក", 420, 29, 18, 25, 6, "bowl");
        seed("Kuy Teav", "Khmer Noodle Soup,Rice Noodle Soup,គុយទាវ", 400, 22, 55, 10, 4, "bowl");
        seed("Lok Lak", "Beef Lok Lak,Shaking Beef,ឡុកឡាក់", 560, 38, 42, 25, 8, "plate");
        seed("Fried Rice", "Khmer Fried Rice,បាយឆា", 510, 18, 72, 17, 5, "plate");
        seed("Chicken Rice", "Rice with Chicken,Hainanese Chicken Rice,បាយមាន់", 520, 32, 65, 15, 4, "plate");
        seed("Hamburger", "Burger,Beef Burger,Hamburger Sandwich", 354, 20, 29, 17, 6, "burger");
        seed("Cheeseburger", "Cheese Burger,Burger with Cheese", 420, 23, 31, 23, 7, "burger");
        seed("Fried Chicken", "Crispy Chicken,Chicken Fry", 320, 25, 11, 21, 1, "piece");
        seed("Pizza", "Cheese Pizza,Pizza Slice", 285, 12, 36, 10, 4, "slice");
        seed("Sandwich", "Chicken Sandwich,Ham Sandwich", 350, 20, 38, 13, 5, "sandwich");
        seed("Salad", "Green Salad,Garden Salad,Vegetable Salad", 150, 5, 18, 7, 6, "bowl");
        seed("French Fries", "Fries,Fried Potatoes", 365, 4, 48, 17, 0, "serving");
        seed("Hot Dog", "Hotdog,Sausage in Bun", 290, 11, 24, 17, 4, "piece");
        seed("Spaghetti", "Pasta,Spaghetti with Tomato Sauce", 330, 12, 58, 7, 8, "plate");
        seed("Sushi", "Sushi Roll,Maki", 300, 13, 50, 6, 7, "serving");
        seed("Ice Cream", "Ice-Cream,Gelato", 270, 5, 32, 14, 25, "cup");
        seed("Cake", "Slice of Cake,Chocolate Cake", 350, 5, 50, 15, 30, "slice");
        seed("Milk Tea", "Bubble Tea,Boba Tea,Pearl Milk Tea", 280, 4, 52, 7, 28, "cup");
    }

    private void seed(String name, String aliases, int calories, int protein, int carbs, int fat, int sugar, String unit) {
        if (repository.findFirstByNameIgnoreCaseAndActiveTrue(name).isPresent()) return;
        FoodNutrition food = new FoodNutrition();
        food.setName(name);
        food.setAliases(aliases);
        food.setCalories(BigDecimal.valueOf(calories));
        food.setProtein(BigDecimal.valueOf(protein));
        food.setCarbs(BigDecimal.valueOf(carbs));
        food.setFat(BigDecimal.valueOf(fat));
        food.setSugar(BigDecimal.valueOf(sugar));
        food.setServingSize(BigDecimal.ONE);
        food.setServingUnit(unit);
        food.setActive(true);
        repository.save(food);
    }
}
