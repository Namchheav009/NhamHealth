package com.nhamhealth.nhamhealth_api.controller.api;

import java.util.Map;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import com.nhamhealth.nhamhealth_api.service.meal.ScrapedMealImportService;

@RestController
@RequestMapping("/api/admin/meals")
public class ScrapedMealImportController {
    private final ScrapedMealImportService imports;

    public ScrapedMealImportController(ScrapedMealImportService imports) {
        this.imports = imports;
    }

    @PostMapping(value = "/import-scraped", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<?> importMeal(@RequestPart("recipe") String recipe,
            @RequestPart(value = "image", required = false) MultipartFile image) {
        try {
            return ResponseEntity.status(201).body(imports.importMeal(recipe, image));
        } catch (IllegalArgumentException exception) {
            return ResponseEntity.badRequest().body(Map.of("message", exception.getMessage()));
        }
    }
}
