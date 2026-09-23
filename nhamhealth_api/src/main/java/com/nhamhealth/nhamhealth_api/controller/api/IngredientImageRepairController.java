package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.nhamhealth.nhamhealth_api.entity.Ingredient;
import com.nhamhealth.nhamhealth_api.entity.IngredientImage;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientImageRepository;
import com.nhamhealth.nhamhealth_api.repository.catalog.IngredientRepository;
import com.nhamhealth.nhamhealth_api.repository.translation.IngredientTranslationRepository;
import com.nhamhealth.nhamhealth_api.entity.IngredientTranslation;

/** Admin-only repair API. The scraper uploads bytes first, then records only the owned URL. */
@RestController
@RequestMapping("/api/admin/ingredients")
public class IngredientImageRepairController {
    private final IngredientRepository ingredients;
    private final IngredientImageRepository images;
    private final IngredientTranslationRepository translations;
    public IngredientImageRepairController(IngredientRepository ingredients, IngredientImageRepository images, IngredientTranslationRepository translations) {
        this.ingredients = ingredients; this.images = images; this.translations = translations;
    }
    @GetMapping("/translation-repair")
    public List<Map<String, Object>> translationRepair() {
        return ingredients.findAllByOrderByIngredientNameAsc().stream().map(i -> {
            String km = translations.findByIngredientIngredientIdAndLanguageCode(i.getIngredientId(), "km").map(IngredientTranslation::getName).orElse("");
            return Map.<String, Object>of("id", i.getIngredientId(), "name", i.getIngredientName(), "nameKm", km);
        }).toList();
    }
    @PutMapping("/{id}/translation")
    public ResponseEntity<?> repairTranslation(@PathVariable Integer id, @RequestBody Map<String, Object> body) {
        Ingredient ingredient = ingredients.findById(id).orElse(null);
        if (ingredient == null) return ResponseEntity.notFound().build();
        String name = String.valueOf(body.getOrDefault("name", ingredient.getIngredientName())).trim();
        String km = String.valueOf(body.getOrDefault("nameKm", "")).trim();
        if (name.isBlank() || km.isBlank()) return ResponseEntity.badRequest().body(Map.of("message", "name and nameKm are required"));
        ingredients.findByIngredientNameIgnoreCase(name).filter(other -> !other.getIngredientId().equals(id)).ifPresent(other -> { throw new IllegalArgumentException("Normalized ingredient already exists: " + name); });
        ingredient.setIngredientName(name); ingredients.save(ingredient);
        IngredientTranslation translation = translations.findByIngredientIngredientIdAndLanguageCode(id, "km").orElseGet(IngredientTranslation::new);
        translation.setIngredient(ingredient); translation.setLanguageCode("km"); translation.setName(km); translations.save(translation);
        return ResponseEntity.ok(Map.of("id", id, "name", name, "nameKm", km));
    }
    @GetMapping("/missing-images")
    public List<Map<String, Object>> missing() {
        return ingredients.findByImageUrlIsNullOrderByIngredientNameAsc().stream()
                .map(i -> Map.<String, Object>of("id", i.getIngredientId(), "name", i.getIngredientName())) .toList();
    }
    @PutMapping("/{id}/image")
    public ResponseEntity<?> setImage(@PathVariable Integer id, @RequestBody Map<String, Object> body) {
        String url = String.valueOf(body.getOrDefault("imageUrl", "")).trim();
        if (url.isBlank()) return ResponseEntity.badRequest().body(Map.of("message", "imageUrl is required"));
        Ingredient ingredient = ingredients.findById(id).orElse(null);
        if (ingredient == null) return ResponseEntity.notFound().build();
        ingredient.setImageUrl(url); ingredients.save(ingredient);
        boolean exists = images.findByIngredientIngredientId(id).stream().anyMatch(x -> url.equals(x.getImageUrl()));
        if (!exists) {
            IngredientImage image = new IngredientImage(); image.setIngredient(ingredient); image.setImageUrl(url);
            image.setSourceType(String.valueOf(body.getOrDefault("imageSource", "SCRAPED")));
            image.setLicenseType(String.valueOf(body.getOrDefault("imageLicense", "UNKNOWN")));
            image.setReviewStatus("PENDING_REVIEW"); image.setIsPrimary(true); images.save(image);
        }
        return ResponseEntity.ok(Map.of("id", id, "imageUrl", url));
    }
}
