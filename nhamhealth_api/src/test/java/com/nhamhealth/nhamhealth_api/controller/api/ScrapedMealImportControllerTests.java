package com.nhamhealth.nhamhealth_api.controller.api;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.jwt;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import java.util.Map;
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
import com.nhamhealth.nhamhealth_api.service.meal.ScrapedMealImportService;

@WebMvcTest(controllers = {ScrapedMealImportController.class, com.nhamhealth.nhamhealth_api.controller.auth.AdminAuthController.class},
        excludeFilters = @org.springframework.context.annotation.ComponentScan.Filter(
                type = org.springframework.context.annotation.FilterType.ANNOTATION,
                classes = org.springframework.web.bind.annotation.ControllerAdvice.class),
        properties = "app.auth.jwt.secret=test-secret-for-import-endpoint-32-characters")
@Import(SecurityConfig.class)
class ScrapedMealImportControllerTests {
    @Autowired MockMvc mvc;
    @MockitoBean ScrapedMealImportService imports;
    @MockitoBean com.nhamhealth.nhamhealth_api.service.auth.AuthService auth;
    @MockitoBean com.nhamhealth.nhamhealth_api.service.auth.LoginAttemptService attempts;
    @MockitoBean com.nhamhealth.nhamhealth_api.service.auth.RegistrationVerificationService verification;
    @MockitoBean DatabaseUserDetailsService users;
    @MockitoBean UserRepository userRepository;
    @MockitoBean ActiveUserJwtValidator activeUsers;
    @MockitoBean org.springframework.cache.CacheManager cacheManager;

    private final MockMultipartFile recipe = new MockMultipartFile("recipe", "", "application/json", "{}".getBytes());
    private final MockMultipartFile image = new MockMultipartFile("image", "meal.webp", "image/webp", new byte[]{1});

    @Test void unauthenticatedCannotImport() throws Exception {
        mvc.perform(multipart("/api/admin/meals/import-scraped").file(recipe).file(image))
                .andExpect(status().isUnauthorized());
        verifyNoInteractions(imports);
    }

    @Test void ordinaryUserCannotImport() throws Exception {
        mvc.perform(multipart("/api/admin/meals/import-scraped").file(recipe).file(image)
                .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_USER"))))
                .andExpect(status().isForbidden());
        verifyNoInteractions(imports);
    }

    @Test void adminMultipartReachesImporter() throws Exception {
        when(imports.importMeal(eq("{}"), any())).thenReturn(Map.of("mealId", 7, "published", false));
        mvc.perform(multipart("/api/admin/meals/import-scraped").file(recipe).file(image)
                .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_ADMIN"))))
                .andExpect(status().isCreated()).andExpect(jsonPath("published").value(false));
    }

    @Test void validationErrorsHaveReadableMessages() throws Exception {
        when(imports.importMeal(anyString(), any())).thenThrow(new IllegalArgumentException("Unknown category"));
        mvc.perform(multipart("/api/admin/meals/import-scraped").file(recipe).file(image)
                .with(jwt().authorities(new SimpleGrantedAuthority("ROLE_ADMIN"))))
                .andExpect(status().isBadRequest()).andExpect(jsonPath("message").value("Unknown category"));
    }

    @Test void adminLoginIsPublicAndReturnsCredentialErrorsFromController() throws Exception {
        when(auth.loginAdmin(any())).thenThrow(new org.springframework.security.authentication.BadCredentialsException("bad"));
        mvc.perform(org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post("/api/admin/auth/login")
                .contentType("application/json").content("{\"email\":\"admin@example.com\",\"password\":\"test\"}"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("message").value("Invalid admin email or password"));
        verify(auth).loginAdmin(any());
        verify(attempts).recordFailure("admin@example.com");
    }
}
