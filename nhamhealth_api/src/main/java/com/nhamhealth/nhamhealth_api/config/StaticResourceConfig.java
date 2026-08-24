package com.nhamhealth.nhamhealth_api.config;

import java.nio.file.Path;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class StaticResourceConfig implements WebMvcConfigurer {

    private final String profileImagesLocation;
    private final String mealImagesLocation;
    private final String recipeStepImagesLocation;
    private final String ingredientImagesLocation;
    private final String postImagesLocation;

    public StaticResourceConfig(@Value("${app.upload.directory:uploads}") String uploadDirectory) {
        Path uploadPath = Path.of(uploadDirectory)
                .toAbsolutePath()
                .normalize();
        this.profileImagesLocation = directoryLocation(uploadPath.resolve("profile-images"));
        this.mealImagesLocation = directoryLocation(uploadPath.resolve("meal-images"));
        this.recipeStepImagesLocation = directoryLocation(uploadPath.resolve("recipe-step-images"));
        this.ingredientImagesLocation = directoryLocation(uploadPath.resolve("ingredient-images"));
        this.postImagesLocation = directoryLocation(uploadPath.resolve("post-images"));
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        registry.addResourceHandler("/uploads/profile-images/**")
                .addResourceLocations(profileImagesLocation);
        registry.addResourceHandler("/uploads/meal-images/**")
                .addResourceLocations(mealImagesLocation);
        registry.addResourceHandler("/uploads/recipe-step-images/**")
                .addResourceLocations(recipeStepImagesLocation);
        registry.addResourceHandler("/uploads/ingredient-images/**")
                .addResourceLocations(ingredientImagesLocation);
        registry.addResourceHandler("/uploads/post-images/**")
                .addResourceLocations(postImagesLocation);
    }

    private String directoryLocation(Path path) {
        String location = path.toUri().toString();
        return location.endsWith("/") ? location : location + "/";
    }
}
