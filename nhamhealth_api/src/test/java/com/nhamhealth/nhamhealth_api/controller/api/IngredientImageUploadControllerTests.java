package com.nhamhealth.nhamhealth_api.controller.api;

import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.context.annotation.Import;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import com.nhamhealth.nhamhealth_api.config.SecurityConfig;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.security.ActiveUserJwtValidator;
import com.nhamhealth.nhamhealth_api.security.DatabaseUserDetailsService;
import com.nhamhealth.nhamhealth_api.service.user.ProfileImageStorageService;

@WebMvcTest(controllers = IngredientImageUploadController.class,
        excludeFilters = @org.springframework.context.annotation.ComponentScan.Filter(
                type = org.springframework.context.annotation.FilterType.ANNOTATION,
                classes = org.springframework.web.bind.annotation.ControllerAdvice.class),
        properties = "app.auth.jwt.secret=test-secret-for-image-endpoint-32-characters")
@Import(SecurityConfig.class)
class IngredientImageUploadControllerTests {
    @Autowired MockMvc mvc;
    @MockitoBean ProfileImageStorageService images;
    @MockitoBean DatabaseUserDetailsService users;
    @MockitoBean UserRepository userRepository;
    @MockitoBean ActiveUserJwtValidator activeUsers;
    @MockitoBean org.springframework.cache.CacheManager cacheManager;

    private final MockMultipartFile image = new MockMultipartFile(
            "file", "garlic.webp", "image/webp", new byte[] { 1 });

    @Test
    void unauthenticatedUploadIsRejected() throws Exception {
        mvc.perform(multipart("/api/admin/ingredient-images").file(image))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(images);
    }

    @Test
    void ordinaryUserUploadIsForbidden() throws Exception {
        mvc.perform(multipart("/api/admin/ingredient-images").file(image)
                .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_USER"))))
                .andExpect(status().isForbidden());
        verifyNoInteractions(images);
    }

    @Test
    void adminBearerTokenCanUpload() throws Exception {
        when(images.storeIngredientImage(image)).thenReturn(
                "https://project.supabase.co/storage/v1/object/public/nhamhealth-images/ingredient-images/garlic.webp");

        mvc.perform(multipart("/api/admin/ingredient-images").file(image)
                .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_ADMIN"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.imageUrl").value(
                        "https://project.supabase.co/storage/v1/object/public/nhamhealth-images/ingredient-images/garlic.webp"));
    }
}
