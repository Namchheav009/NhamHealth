package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;

/** Bearer-authenticated ingredient image upload used by the recipe scraper. */
@RestController
@RequestMapping("/api/admin/ingredient-images")
public class IngredientImageUploadController {

    private final ProfileImageStorageService images;

    public IngredientImageUploadController(ProfileImageStorageService images) {
        this.images = images;
    }

    @PostMapping(consumes = "multipart/form-data")
    public ResponseEntity<?> upload(@RequestParam("file") MultipartFile file) {
        try {
            return ResponseEntity.ok(Map.of("imageUrl", images.storeIngredientImage(file)));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        } catch (IllegalStateException exception) {
            return ResponseEntity.internalServerError().body(Map.of("message", exception.getMessage()));
        }
    }
}
