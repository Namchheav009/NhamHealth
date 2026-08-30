package com.nhamhealth.nhamhealth_api.config;

import java.math.BigDecimal;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.dao.DataAccessException;
import org.springframework.stereotype.Component;
import org.springframework.transaction.TransactionException;
import com.nhamhealth.nhamhealth_api.entity.FoodNutrition;
import com.nhamhealth.nhamhealth_api.repository.FoodNutritionRepository;

/**
 * Adds a baseline catalog without replacing administrator-managed nutrition data.
 * Values are approximate examples and are not medical-grade nutrition data.
 */
@Component
public class DevFoodNutritionDataLoader implements CommandLineRunner {
    private static final Logger log = LoggerFactory.getLogger(DevFoodNutritionDataLoader.class);
    private final FoodNutritionRepository repository;
    public DevFoodNutritionDataLoader(FoodNutritionRepository repository) { this.repository = repository; }

    @Override
    public void run(String... args) {
        try {
            refreshCatalog();
        } catch (DataAccessException | TransactionException error) {
            log.warn("Food nutrition catalog refresh was skipped because the database is temporarily unavailable. The API will continue starting: {}",
                    rootMessage(error));
        }
    }

    private void refreshCatalog() {
        seed("Bai Sach Chrouk", "Pork Rice,Rice with Pork,Grilled Pork Rice,បាយសាច់ជ្រូក", 500, 25, 65, 16, 5, "plate");
        seed("Num Banh Chok", "Khmer Noodles,Nom Banh Chok,នំបញ្ចុក", 380, 14, 62, 9, 7, "bowl");
        seed("Fish Amok", "Amok Trey,Khmer Fish Curry,អាម៉ុកត្រី", 420, 29, 18, 25, 6, "bowl");
        seed("Kuy Teav", "Khmer Noodle Soup,Rice Noodle Soup,គុយទាវ", 400, 22, 55, 10, 4, "bowl");
        seed("Samlor Korko", "Somlor Korko,Cambodian Vegetable Soup,Khmer Vegetable Stew,សម្លកកូរ", 310, 18, 28, 14, 7, "bowl");
        seed("Samlor Machu Kreung", "Somlor Machu Kreung,Cambodian Sour Herb Soup,Khmer Sour Soup,សម្លម្ជូរគ្រឿង", 270, 24, 16, 12, 5, "bowl");
        seed("Samlor Machu Youn", "Somlor Machu Youn,Cambodian Sour Fish Soup,Vietnamese Sour Soup,សម្លម្ជូរយួន", 210, 20, 20, 6, 9, "bowl");
        seed("Sngor Ngam Ngov", "Sngor Chrouk,Khmer Pickled Lime Chicken Soup,Cambodian Chicken Lime Soup,ស្ងោរង៉ាំង៉ូវ", 240, 28, 12, 9, 4, "bowl");
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
        seed("Milk Tea", "Bubble Tea,Boba Tea,Pearl Milk Tea,Matcha Bubble Tea,Matcha Milk Tea,Green Milk Tea,Green Bubble Tea", 280, 4, 52, 7, 28, "cup");
        seed("Water", "Drinking Water,Mineral Water", 0, 0, 0, 0, 0, "glass");
        seed("Black Coffee", "Coffee,Americano,Hot Coffee", 5, 0, 1, 0, 0, "cup");
        seed("Coffee with Milk", "Latte,Cafe Latte,Milk Coffee,Iced Coffee,Iced Latte,Iced Milk Coffee", 150, 8, 14, 6, 12, "cup");
        seed("Orange Juice", "Fresh Orange Juice,OJ", 112, 2, 26, 0, 21, "glass");
        seed("Cola", "Soda,Soft Drink,Coke", 140, 0, 39, 0, 39, "can");
        seed("Green Tea", "Unsweetened Green Tea,Hot Green Tea", 2, 0, 0, 0, 0, "cup");
        seed("Smoothie", "Fruit Smoothie,Fruit Shake", 220, 4, 48, 3, 34, "glass");
        seedMeasured("Cooked Jasmine Rice", "Cooked Rice,White Rice,Steamed Rice,Jasmine Rice Cooked",
                130, 2.7, 28, 0.3, 0.1, 0.4, 1, 100, "g");
        seedMeasured("Grilled Chicken Breast", "Grilled Chicken,Chicken Breast Grilled,Sliced Grilled Chicken",
                165, 31, 0, 3.6, 0, 0, 74, 100, "g");
        seedMeasured("Grilled Pork", "Barbecued Pork,BBQ Pork,Sliced Grilled Pork",
                242, 27, 0, 14, 0, 0, 75, 100, "g");
        seedMeasured("Sweet Chili Sauce", "Chili Sauce,Thai Sweet Chili Sauce,Orange Red Sauce",
                240, 0.7, 60, 0.2, 55, 0.5, 1_000, 100, "g");
        seedMeasured("Cooked Tapioca Pearls", "Tapioca Pearls,Boba Pearls,Bubble Tea Pearls",
                160, 0.2, 38, 0, 5, 0.3, 5, 100, "g");
    }

    private String rootMessage(Throwable error) {
        Throwable root = error;
        while (root.getCause() != null && root.getCause() != root) root = root.getCause();
        String message = root.getMessage();
        return message == null || message.isBlank()
                ? root.getClass().getSimpleName()
                : message.replaceAll("[\\r\\n\\t]+", " ");
    }

    private void seed(String name, String aliases, int calories, int protein, int carbs, int fat, int sugar, String unit) {
        var existing = repository.findFirstByNameIgnoreCaseAndActiveTrue(name);
        if (existing.isPresent()) {
            FoodNutrition food = existing.get();
            if (!aliases.equals(food.getAliases())) {
                food.setAliases(aliases);
                repository.save(food);
            }
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
        food.setActive(true);
        repository.save(food);
    }

    private void seedMeasured(
            String name, String aliases,
            double calories, double protein, double carbs, double fat, double sugar,
            double fiber, double sodium, double servingSize, String unit) {
        if (repository.findFirstByNameIgnoreCaseAndActiveTrue(name).isPresent()) return;
        FoodNutrition food = new FoodNutrition();
        food.setName(name);
        food.setAliases(aliases);
        food.setCalories(BigDecimal.valueOf(calories));
        food.setProtein(BigDecimal.valueOf(protein));
        food.setCarbs(BigDecimal.valueOf(carbs));
        food.setFat(BigDecimal.valueOf(fat));
        food.setSugar(BigDecimal.valueOf(sugar));
        food.setFiber(BigDecimal.valueOf(fiber));
        food.setSodium(BigDecimal.valueOf(sodium));
        food.setServingSize(BigDecimal.valueOf(servingSize));
        food.setServingUnit(unit);
        food.setActive(true);
        repository.save(food);
    }
}
