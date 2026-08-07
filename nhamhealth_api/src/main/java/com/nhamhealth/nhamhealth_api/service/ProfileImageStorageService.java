package com.nhamhealth.nhamhealth_api.service;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.util.Map;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
public class ProfileImageStorageService {

    private static final long MAX_IMAGE_SIZE_BYTES = 5 * 1024 * 1024;
    private static final Map<String, String> EXTENSIONS = Map.of(
            "image/jpeg", "jpg",
            "image/png", "png",
            "image/webp", "webp");

    private final Path profileImageDirectory;
    private final Path mealImageDirectory;
    private final Path recipeStepImageDirectory;
    private final Path ingredientImageDirectory;

    public ProfileImageStorageService(@Value("${app.upload.directory:uploads}") String uploadDirectory) {
        this.profileImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("profile-images");
        this.mealImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("meal-images");
        this.recipeStepImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("recipe-step-images");
        this.ingredientImageDirectory = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize()
                .resolve("ingredient-images");
    }

    public String storeProfileImage(MultipartFile file) {
        return storeImage(file, profileImageDirectory, "/uploads/profile-images/", "Profile");
    }

    public String storeMealImage(MultipartFile file) {
        return storeImage(file, mealImageDirectory, "/uploads/meal-images/", "Meal");
    }

    public String storeRecipeStepImage(MultipartFile file) {
        return storeImage(file, recipeStepImageDirectory, "/uploads/recipe-step-images/", "Recipe step");
    }

    public String storeIngredientImage(MultipartFile file) {
        return storeImage(file, ingredientImageDirectory, "/uploads/ingredient-images/", "Ingredient");
    }

    private String storeImage(MultipartFile file, Path imageDirectory, String publicPath, String imageLabel) {
        if (file == null || file.isEmpty()) {
            throw new IllegalArgumentException("Please choose an image file");
        }
        if (file.getSize() > MAX_IMAGE_SIZE_BYTES) {
            throw new IllegalArgumentException(imageLabel + " images must be 5 MB or smaller");
        }

        String contentType = file.getContentType();
        String extension = EXTENSIONS.get(contentType);
        if (extension == null) {
            throw new IllegalArgumentException(imageLabel + " image must be a JPG, PNG, or WebP file");
        }

        try {
            Files.createDirectories(imageDirectory);
            String filename = UUID.randomUUID() + "." + extension;
            try (var inputStream = file.getInputStream()) {
                Files.copy(inputStream, imageDirectory.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
            }
            return publicPath + filename;
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to store the " + imageLabel.toLowerCase() + " image", exception);
        }
    }
}
