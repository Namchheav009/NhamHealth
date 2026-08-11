package com.nhamhealth.nhamhealth_api.service;

import java.io.IOException;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Duration;
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
    private final String supabaseUrl;
    private final String supabaseServiceKey;
    private final String supabaseBucket;
    private final HttpClient httpClient;

    public ProfileImageStorageService(
            @Value("${app.upload.directory:uploads}") String uploadDirectory,
            @Value("${app.storage.supabase.url:}") String supabaseUrl,
            @Value("${app.storage.supabase.service-key:}") String supabaseServiceKey,
            @Value("${app.storage.supabase.bucket:nhamhealth-images}") String supabaseBucket) {
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
        this.supabaseUrl = stripTrailingSlash(supabaseUrl);
        this.supabaseServiceKey = supabaseServiceKey == null ? "" : supabaseServiceKey.trim();
        this.supabaseBucket = supabaseBucket == null ? "nhamhealth-images" : supabaseBucket.trim();
        this.httpClient = HttpClient.newBuilder()
                .connectTimeout(Duration.ofSeconds(10))
                .build();
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

    public boolean isStoredMealImageUrl(String imageUrl) {
        return isStoredImageUrl(imageUrl, "/uploads/meal-images/", "meal-images");
    }

    public boolean isStoredRecipeStepImageUrl(String imageUrl) {
        return isStoredImageUrl(imageUrl, "/uploads/recipe-step-images/", "recipe-step-images");
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
            String filename = UUID.randomUUID() + "." + extension;
            if (usesSupabaseStorage()) {
                return storeInSupabase(file, imageDirectory.getFileName().toString(), filename, contentType, imageLabel);
            }

            Files.createDirectories(imageDirectory);
            try (var inputStream = file.getInputStream()) {
                Files.copy(inputStream, imageDirectory.resolve(filename), StandardCopyOption.REPLACE_EXISTING);
            }
            return publicPath + filename;
        } catch (IOException exception) {
            throw new IllegalStateException("Unable to store the " + imageLabel.toLowerCase() + " image", exception);
        }
    }

    private boolean usesSupabaseStorage() {
        return !supabaseUrl.isBlank() && !supabaseServiceKey.isBlank() && !supabaseBucket.isBlank();
    }

    private boolean isStoredImageUrl(String imageUrl, String localPathPrefix, String storageFolder) {
        if (imageUrl == null || imageUrl.isBlank()) {
            return false;
        }

        String normalizedUrl = imageUrl.trim();
        if (normalizedUrl.startsWith(localPathPrefix)) {
            return true;
        }

        String sharedStoragePrefix = supabaseUrl + "/storage/v1/object/public/"
                + supabaseBucket + "/" + storageFolder + "/";
        return usesSupabaseStorage() && normalizedUrl.startsWith(sharedStoragePrefix);
    }

    private String storeInSupabase(
            MultipartFile file,
            String folder,
            String filename,
            String contentType,
            String imageLabel) throws IOException {
        String objectPath = folder + "/" + filename;
        URI uploadUri = URI.create(supabaseUrl + "/storage/v1/object/" + supabaseBucket + "/" + objectPath);
        HttpRequest.Builder requestBuilder = HttpRequest.newBuilder(uploadUri)
                .timeout(Duration.ofSeconds(30))
                .header("apikey", supabaseServiceKey)
                .header("Content-Type", contentType)
                .POST(HttpRequest.BodyPublishers.ofByteArray(file.getBytes()));

        // New sb_secret_ keys are sent with apikey only. Legacy service_role
        // JWT keys also need the Bearer header for Storage authorization.
        if (!supabaseServiceKey.startsWith("sb_secret_")) {
            requestBuilder.header("Authorization", "Bearer " + supabaseServiceKey);
        }
        HttpRequest request = requestBuilder.build();

        try {
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() < 200 || response.statusCode() >= 300) {
                throw new IllegalStateException("Unable to store the " + imageLabel.toLowerCase()
                        + " image in shared storage (HTTP " + response.statusCode() + ")");
            }
        } catch (InterruptedException exception) {
            Thread.currentThread().interrupt();
            throw new IllegalStateException("Image upload was interrupted", exception);
        }

        return supabaseUrl + "/storage/v1/object/public/" + supabaseBucket + "/" + objectPath;
    }

    private String stripTrailingSlash(String value) {
        if (value == null) {
            return "";
        }
        String normalized = value.trim();
        while (normalized.endsWith("/")) {
            normalized = normalized.substring(0, normalized.length() - 1);
        }
        return normalized;
    }
}
