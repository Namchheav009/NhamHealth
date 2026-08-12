package com.nhamhealth.nhamhealth_api.auth;

import java.time.LocalDateTime;
import java.util.UUID;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.multipart;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.redirectedUrl;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.when;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.context.bean.override.mockito.MockitoBean;

import com.jayway.jsonpath.JsonPath;
import com.nhamhealth.nhamhealth_api.entity.MealCategory;
import com.nhamhealth.nhamhealth_api.repository.IngredientRepository;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.repository.MealCategoryRepository;
import com.nhamhealth.nhamhealth_api.repository.RecipeStepRepository;
import com.nhamhealth.nhamhealth_api.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.TagTypeRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.WellnessProfileRepository;
import com.nhamhealth.nhamhealth_api.service.GoogleTokenVerifier;

@SpringBootTest
@AutoConfigureMockMvc
class AuthenticationFlowTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private WellnessProfileRepository wellnessProfileRepository;

    @Autowired
    private MealCategoryRepository mealCategoryRepository;

    @Autowired
    private RecipeStepRepository recipeStepRepository;

    @Autowired
    private IngredientRepository ingredientRepository;

    @Autowired
    private TagTypeRepository tagTypeRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @MockitoBean
    private GoogleTokenVerifier googleTokenVerifier;

    @BeforeEach
    void createTestAccounts() {
        Role adminRole = findOrCreateRole("ADMIN");
        Role userRole = findOrCreateRole("USER");
        createUserIfMissing("admin@nhamhealth.local", "Admin123!", adminRole);
        createUserIfMissing("user@nhamhealth.local", "User123!", userRole);
    }

    @Test
    void mobileUserReceivesBearerTokenAndCanReadProfile() throws Exception {
        MvcResult result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"user@nhamhealth.local","password":"User123!"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.expiresIn").value(86400))
                .andExpect(jsonPath("$.user.id").isNumber())
                .andExpect(jsonPath("$.user.email").value("user@nhamhealth.local"))
                .andExpect(jsonPath("$.user.role").value("USER"))
                .andReturn();

        String accessToken = JsonPath.read(
                result.getResponse().getContentAsString(), "$.accessToken");
        mockMvc.perform(get("/api/v1/auth/me")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber())
                .andExpect(jsonPath("$.email").value("user@nhamhealth.local"))
                .andExpect(jsonPath("$.role").value("USER"));

        MockMultipartFile imageFile = new MockMultipartFile(
                "file", "profile.png", MediaType.IMAGE_PNG_VALUE, new byte[] { 1, 2, 3 });
        mockMvc.perform(multipart("/api/v1/users/me/profile-image")
                        .file(imageFile)
                        .with(request -> {
                            request.setMethod("PUT");
                            return request;
                        })
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                        .contentType(MediaType.MULTIPART_FORM_DATA))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profileImageUrl").value(org.hamcrest.Matchers.startsWith("/uploads/profile-images/")));

        mockMvc.perform(get("/api/v1/auth/me")
                        .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profileImageUrl")
                        .value(org.hamcrest.Matchers.startsWith("/uploads/profile-images/")));

        User user = userRepository.findByEmailIgnoreCase("user@nhamhealth.local").orElseThrow();
        assertTrue(userProfileRepository.findByUser_UserId(user.getUserId())
                .map(profile -> profile.getProfileImageUrl().startsWith("/uploads/profile-images/"))
                .orElse(false));
    }

    @Test
    void invalidMobileCredentialsReturnUnauthorized() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"user@nhamhealth.local","password":"wrong"}
                                """))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.message").value("Invalid email or password"));
    }

    @Test
    void invalidMobileLoginPayloadAlwaysReturnsJson() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .accept(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"not-an-email","password":""}
                                """))
                .andExpect(status().isBadRequest())
                .andExpect(content().contentTypeCompatibleWith(MediaType.APPLICATION_JSON))
                .andExpect(jsonPath("$.message").isNotEmpty());
    }

    @Test
    void userCanRegisterAndImmediatelyReceiveBearerToken() throws Exception {
        String email = "new-" + UUID.randomUUID() + "@example.com";

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"New User","email":"%s","password":"StrongPass123!"}
                                """.formatted(email)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.tokenType").value("Bearer"))
                .andExpect(jsonPath("$.user.email").value(email))
                .andExpect(jsonPath("$.user.role").value("USER"))
                .andExpect(jsonPath("$.user.fullName").value("New User"))
                .andExpect(jsonPath("$.user.profileImageUrl").isEmpty());
    }

    @Test
    void googleLoginRefreshesTheLinkedUsersRealProfile() throws Exception {
        String email = "google-linked-" + UUID.randomUUID() + "@example.com";
        Role userRole = findOrCreateRole("USER");

        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode("StrongPass123!"));
        user.setRole(userRole);
        user.setStatus("ACTIVE");
        user.setIsVerified(true);
        user.setVerifiedAt(LocalDateTime.now());
        user = userRepository.save(user);

        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName("Old Profile Name");
        profile.setProfileImageUrl(null);
        profile.setCreatedAt(LocalDateTime.now());
        profile.setUpdatedAt(LocalDateTime.now());
        userProfileRepository.save(profile);

        String googlePicture = "https://lh3.googleusercontent.com/a/google-profile";
        when(googleTokenVerifier.verify("linked-google-token"))
                .thenReturn(new GoogleTokenVerifier.GoogleIdentity(
                        "google-subject-" + UUID.randomUUID(),
                        email,
                        "Google Profile Name",
                        googlePicture));

        mockMvc.perform(post("/api/v1/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"idToken":"linked-google-token"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.user.email").value(email))
                .andExpect(jsonPath("$.user.fullName").value("Google Profile Name"))
                .andExpect(jsonPath("$.user.profileImageUrl").value(googlePicture));

        UserProfile refreshed = userProfileRepository
                .findByUser_UserId(user.getUserId())
                .orElseThrow();
        assertEquals("Google Profile Name", refreshed.getFullName());
        assertEquals(googlePicture, refreshed.getProfileImageUrl());
    }

    @Test
    void registrationRejectsAnExistingEmail() throws Exception {
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Existing User","email":"user@nhamhealth.local","password":"StrongPass123!"}
                                """))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.message")
                        .value("An account with this email already exists"));
    }

    @Test
    void adminAccountIsDirectedToTheWebsiteInsteadOfMobileLogin() throws Exception {
        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"email":"admin@nhamhealth.local","password":"Admin123!"}
                                """))
                .andExpect(status().isForbidden());
    }

    @Test
    void adminCanUseFormLoginAndOpenDashboard() throws Exception {
        mockMvc.perform(post("/login")
                        .with(csrf())
                        .param("email", "admin@nhamhealth.local")
                        .param("password", "Admin123!"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/dashboard?login=success"));

        mockMvc.perform(get("/dashboard").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/dashboard"));
    }

    @Test
    void adminCanCreateAUserFromTheAdminPortal() throws Exception {
        String email = "admin-created-" + UUID.randomUUID() + "@example.com";

        mockMvc.perform(post("/admin/users")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Portal Created User","email":"%s","password":"StrongPass123!","role":"USER"}
                                """.formatted(email)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.email").value(email))
                .andExpect(jsonPath("$.name").value("Portal Created User"))
                .andExpect(jsonPath("$.role").value("USER"));

        assertTrue(userRepository.findByEmailIgnoreCase(email).isPresent());
    }

    @Test
    void adminCanUpdateAndDeleteAUserFromTheAdminPortal() throws Exception {
        String email = "managed-" + UUID.randomUUID() + "@example.com";
        MvcResult createResult = mockMvc.perform(post("/admin/users")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Managed User","email":"%s","password":"StrongPass123!","role":"USER"}
                                """.formatted(email)))
                .andExpect(status().isCreated())
                .andReturn();
        Integer userId = JsonPath.read(createResult.getResponse().getContentAsString(), "$.id");

        mockMvc.perform(put("/admin/users/{userId}", userId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"fullName":"Updated User","email":"%s","password":"","role":"USER","status":"SUSPENDED","verified":false}
                                """.formatted(email)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.name").value("Updated User"))
                .andExpect(jsonPath("$.status").value("SUSPENDED"))
                .andExpect(jsonPath("$.verified").value(false));

        mockMvc.perform(delete("/admin/users/{userId}", userId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isNoContent());

        assertTrue(userRepository.findById(userId)
                .map(user -> "DELETED".equals(user.getStatus()) && !user.getIsVerified())
                .orElse(false));

        mockMvc.perform(get("/admin/users").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/users"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Edit user")));
    }

    @Test
    void adminCanUploadAProfileImageFromThePortal() throws Exception {
        MockMultipartFile imageFile = new MockMultipartFile(
                "file", "admin-profile.webp", "image/webp", new byte[] { 1, 2, 3 });

        MvcResult result = mockMvc.perform(multipart("/admin/profile-images")
                        .file(imageFile)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.profileImageUrl").value(org.hamcrest.Matchers.startsWith("/uploads/profile-images/")))
                .andReturn();

        String imageUrl = JsonPath.read(result.getResponse().getContentAsString(), "$.profileImageUrl");
        mockMvc.perform(get(imageUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/webp"));
    }

    @Test
    void adminCanCreateAndViewAWellnessProfileFromTheAdminPortal() throws Exception {
        MvcResult result = mockMvc.perform(post("/admin/wellness-profiles")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                        {"userEmail":"user@nhamhealth.local","profileImageUrl":"/uploads/user.jpg","gender":"Female","dateOfBirth":"1995-05-15","heightCm":175.0,"weightKg":72.0,"activityLevel":"MODERATE"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.email").value("user@nhamhealth.local"))
                .andExpect(jsonPath("$.profileImageUrl").value("/uploads/user.jpg"))
                .andExpect(jsonPath("$.gender").value("Female"))
                .andExpect(jsonPath("$.activityLevel").value("MODERATE"))
                .andExpect(jsonPath("$.complete").value(true))
                .andReturn();

        mockMvc.perform(get("/admin/wellness-profiles").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/wellness-profiles"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Wellness profiles")));

        Integer wellnessProfileId = JsonPath.read(result.getResponse().getContentAsString(), "$.id");
        mockMvc.perform(post("/admin/wellness-profiles")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                        {"userEmail":"user@nhamhealth.local","profileImageUrl":"/uploads/user.jpg","gender":"Other","dateOfBirth":"1995-05-15","heightCm":180.0,"weightKg":75.0,"activityLevel":"HIGH"}
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(wellnessProfileId))
                .andExpect(jsonPath("$.gender").value("Other"))
                .andExpect(jsonPath("$.activityLevel").value("HIGH"));

        mockMvc.perform(delete("/admin/wellness-profiles/{wellnessProfileId}", wellnessProfileId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isNoContent());
        assertTrue(wellnessProfileRepository.findById(wellnessProfileId).isEmpty());
    }

    @Test
    void adminCanCreateAndViewAMealFromTheAdminPortal() throws Exception {
        MealCategory category = new MealCategory();
        category.setCategoryName("Test category " + UUID.randomUUID());
        category.setDescription("Category used by the admin meal integration test");
        category.setSortOrder(1);
        category.setIsActive(true);
        category = mealCategoryRepository.save(category);

        MockMultipartFile mealImage = new MockMultipartFile(
                "file", "portal-meal.png", MediaType.IMAGE_PNG_VALUE, new byte[] { 1, 2, 3 });
        MvcResult imageResult = mockMvc.perform(multipart("/admin/meal-images")
                        .file(mealImage)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mainImageUrl").value(org.hamcrest.Matchers.startsWith("/uploads/meal-images/")))
                .andReturn();
        String mealImageUrl = JsonPath.read(imageResult.getResponse().getContentAsString(), "$.mainImageUrl");

        MockMultipartFile recipeStepImage = new MockMultipartFile(
                "file", "portal-step.webp", "image/webp", new byte[] { 4, 5, 6 });
        MvcResult stepImageResult = mockMvc.perform(multipart("/admin/recipe-step-images")
                        .file(recipeStepImage)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.imageUrl").value(org.hamcrest.Matchers.startsWith("/uploads/recipe-step-images/")))
                .andReturn();
        String stepImageUrl = JsonPath.read(stepImageResult.getResponse().getContentAsString(), "$.imageUrl");
        mockMvc.perform(get(stepImageUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType("image/webp"));

        MvcResult result = mockMvc.perform(post("/admin/meals")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"mealName":"Portal Meal","categoryId":%d,"calories":420,"servings":2,"description":"Created from the admin portal","difficulty":"Easy","cookingTimeMinutes":20,"published":true,"mainImageUrl":"%s","recipeSteps":[{"title":"Prepare","instruction":"Wash and prepare the ingredients.","imageUrl":"%s"},{"title":"Cook","instruction":"Cook until ready to serve.","imageUrl":"%s"}]}
                                """.formatted(category.getCategoryId(), mealImageUrl, stepImageUrl, stepImageUrl)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.mealName").value("Portal Meal"))
                .andExpect(jsonPath("$.category").value(category.getCategoryName()))
                .andExpect(jsonPath("$.calories").value("420 kcal"))
                .andExpect(jsonPath("$.status").value("Published"))
                .andExpect(jsonPath("$.mainImageUrl").value(mealImageUrl))
                .andReturn();

        Integer mealId = JsonPath.read(result.getResponse().getContentAsString(), "$.mealId");
        assertTrue(recipeStepRepository.findByMealMealIdOrderByStepNumberAsc(mealId).stream()
                .map(step -> step.getStepNumber() + ":" + step.getInstruction())
                .toList()
                .equals(java.util.List.of("1:Wash and prepare the ingredients.", "2:Cook until ready to serve.")));
        assertTrue(recipeStepRepository.findByMealMealIdOrderByStepNumberAsc(mealId).stream()
                .allMatch(step -> stepImageUrl.equals(step.getImageUrl())));

        mockMvc.perform(get("/admin/meals/{mealId}", mealId).with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mealName").value("Portal Meal"))
                .andExpect(jsonPath("$.recipeSteps.length()").value(2));

        mockMvc.perform(put("/admin/meals/{mealId}", mealId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"mealName":"Updated Portal Meal","categoryId":%d,"calories":510,"servings":3,"description":"Updated through the admin portal","difficulty":"Medium","cookingTimeMinutes":35,"published":false,"mainImageUrl":"%s","recipeSteps":[{"title":"Prepare ingredients","instruction":"Prepare all ingredients.","imageUrl":"%s"}]}
                                """.formatted(category.getCategoryId(), mealImageUrl, stepImageUrl)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.mealName").value("Updated Portal Meal"))
                .andExpect(jsonPath("$.status").value("Draft"));
        assertTrue(recipeStepRepository.findByMealMealIdOrderByStepNumberAsc(mealId).size() == 1);

        mockMvc.perform(get("/admin/meals").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/meals"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("Loading meals...")));

        mockMvc.perform(delete("/admin/meals/{mealId}", mealId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isNoContent());
        mockMvc.perform(get("/admin/meals/{mealId}", mealId).with(user("admin").roles("ADMIN")))
                .andExpect(status().isNotFound());
    }

    @Test
    void adminCanManageMealCategoriesFromTheAdminPortal() throws Exception {
        String categoryName = "PC-" + UUID.randomUUID();
        MvcResult result = mockMvc.perform(post("/admin/meal-categories")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"categoryName":"%s","description":"Created by the admin portal","active":true,"sortOrder":50}
                                """.formatted(categoryName)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.categoryName").value(categoryName))
                .andExpect(jsonPath("$.active").value(true))
                .andReturn();

        Integer categoryId = JsonPath.read(result.getResponse().getContentAsString(), "$.categoryId");
        mockMvc.perform(put("/admin/meal-categories/{categoryId}", categoryId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"categoryName":"%s","description":"Updated category","active":false,"sortOrder":25}
                                """.formatted(categoryName)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.description").value("Updated category"))
                .andExpect(jsonPath("$.active").value(false))
                .andExpect(jsonPath("$.sortOrder").value(25));

        mockMvc.perform(get("/admin/meal-categories").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/meal-categories"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("data-action=\"edit\"")));

        mockMvc.perform(delete("/admin/meal-categories/{categoryId}", categoryId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isNoContent());
        assertTrue(mealCategoryRepository.findById(categoryId).isEmpty());
    }

    @Test
    void adminCanManageIngredientsFromTheAdminPortal() throws Exception {
        String ingredientName = "Ingredient " + UUID.randomUUID();
        MockMultipartFile ingredientImage = new MockMultipartFile(
                "file", "ingredient.png", MediaType.IMAGE_PNG_VALUE, new byte[] { 7, 8, 9 });
        MvcResult imageResult = mockMvc.perform(multipart("/admin/ingredient-images")
                        .file(ingredientImage)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.imageUrl").value(org.hamcrest.Matchers.startsWith("/uploads/ingredient-images/")))
                .andReturn();
        String ingredientImageUrl = JsonPath.read(imageResult.getResponse().getContentAsString(), "$.imageUrl");
        mockMvc.perform(get(ingredientImageUrl))
                .andExpect(status().isOk())
                .andExpect(content().contentType(MediaType.IMAGE_PNG));

        MvcResult result = mockMvc.perform(post("/admin/ingredients")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"ingredientName":"%s","ingredientType":"Vegetable","defaultUnit":"g","description":"Created from the admin portal","imageUrl":"%s"}
                                """.formatted(ingredientName, ingredientImageUrl)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.ingredientName").value(ingredientName))
                .andExpect(jsonPath("$.ingredientType").value("Vegetable"))
                .andExpect(jsonPath("$.imageUrl").value(ingredientImageUrl))
                .andReturn();

        Integer ingredientId = JsonPath.read(result.getResponse().getContentAsString(), "$.ingredientId");
        mockMvc.perform(put("/admin/ingredients/{ingredientId}", ingredientId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"ingredientName":"%s","ingredientType":"Leafy vegetable","defaultUnit":"cup","description":"Updated ingredient","imageUrl":"%s"}
                                """.formatted(ingredientName, ingredientImageUrl)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.ingredientType").value("Leafy vegetable"))
                .andExpect(jsonPath("$.defaultUnit").value("cup"))
                .andExpect(jsonPath("$.imageUrl").value(ingredientImageUrl));

        mockMvc.perform(get("/admin/ingredients").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/ingredients"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("data-action=\"edit\"")));

        mockMvc.perform(delete("/admin/ingredients/{ingredientId}", ingredientId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isNoContent());
        assertTrue(ingredientRepository.findById(ingredientId).isEmpty());
    }

    @Test
    void adminCanManageTagsFromTheAdminPortal() throws Exception {
        String tagName = "Tag " + UUID.randomUUID();
        MvcResult result = mockMvc.perform(post("/admin/tags")
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"tagName":"%s","tagScope":"NUTRITION","description":"Created from the admin portal","active":true}
                                """.formatted(tagName)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").isNumber())
                .andReturn();

        Integer tagId = JsonPath.read(result.getResponse().getContentAsString(), "$.id");
        mockMvc.perform(put("/admin/tags/{tagId}", tagId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf())
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {"tagName":"%s","tagScope":"HEALTH","description":"Updated tag","active":false}
                                """.formatted(tagName)))
                .andExpect(status().isOk());

        mockMvc.perform(get("/admin/tags").with(user("admin").roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/tags"))
                .andExpect(content().string(org.hamcrest.Matchers.containsString("data-id=\"" + tagId + "\"")));

        mockMvc.perform(delete("/admin/tags/{tagId}", tagId)
                        .with(user("admin").roles("ADMIN"))
                        .with(csrf()))
                .andExpect(status().isNoContent());
        assertTrue(tagTypeRepository.findById(tagId).isEmpty());
    }

    @Test
    void regularUserCannotUseAdminFormLogin() throws Exception {
        mockMvc.perform(post("/login")
                        .with(csrf())
                        .param("email", "user@nhamhealth.local")
                        .param("password", "User123!"))
                .andExpect(status().is3xxRedirection())
                .andExpect(redirectedUrl("/login?error=not-admin"));
    }

    private Role findOrCreateRole(String roleName) {
        return roleRepository.findByRoleNameIgnoreCase(roleName).orElseGet(() -> {
            Role role = new Role();
            role.setRoleName(roleName);
            return roleRepository.save(role);
        });
    }

    private void createUserIfMissing(String email, String password, Role role) {
        if (userRepository.findByEmailIgnoreCase(email).isPresent()) {
            return;
        }

        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setRole(role);
        user.setStatus("ACTIVE");
        user.setIsVerified(true);
        user.setVerifiedAt(LocalDateTime.now());
        userRepository.save(user);
    }
}
