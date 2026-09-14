package com.nhamhealth.nhamhealth_api.controller.admin;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.webmvc.test.autoconfigure.AutoConfigureMockMvc;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import org.springframework.test.web.servlet.MockMvc;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.model;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.view;

import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserSetting;
import com.nhamhealth.nhamhealth_api.repository.auth.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserSettingRepository;

@SpringBootTest
@AutoConfigureMockMvc
class SettingAdminControllerTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private UserSettingRepository settingRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private com.nhamhealth.nhamhealth_api.repository.catalog.TagTypeRepository tagTypeRepository;

    @Autowired
    private com.nhamhealth.nhamhealth_api.repository.catalog.ServingSizeRepository servingSizeRepository;

    private User adminUser;

    @BeforeEach
    void setUp() {
        Role adminRole = roleRepository.findByRoleNameIgnoreCase("ADMIN")
                .orElseGet(() -> {
                    Role r = new Role();
                    r.setRoleName("ADMIN");
                    return roleRepository.save(r);
                });

        adminUser = userRepository.findByEmailIgnoreCase("admin_theme_test@example.com")
                .orElseGet(() -> {
                    User u = new User();
                    u.setEmail("admin_theme_test@example.com");
                    u.setPasswordHash("$2a$10$dummyhashfortestonly12345678901234567890123456789012");
                    u.setRole(adminRole);
                    u.setStatus("ACTIVE");
                    u.setIsVerified(true);
                    return userRepository.saveAndFlush(u);
                });
    }

    @Test
    void settingsPage_loadsAdminTheme() throws Exception {
        mockMvc.perform(get("/admin/settings")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/setting"))
                .andExpect(model().attributeExists("adminTheme"));
    }

    @Test
    void saveSettings_persistsTheme() throws Exception {
        mockMvc.perform(post("/admin/settings")
                .with(user(adminUser.getEmail()).roles("ADMIN"))
                .with(csrf())
                .header("Accept", "application/json")
                .param("languageCode", "en")
                .param("theme", "dark")
                .param("emailNotifications", "true")
                .param("pushNotifications", "true"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Your preferences were saved."));

        UserSetting setting = settingRepository.findByUserUserId(adminUser.getUserId()).orElse(null);
        assertThat(setting).isNotNull();
        assertThat(setting.getTheme()).isEqualTo("dark");
    }

    @Test
    void saveSettings_nativeBrowserSubmit_redirects() throws Exception {
        mockMvc.perform(post("/admin/settings")
                .with(user(adminUser.getEmail()).roles("ADMIN"))
                .with(csrf())
                .header("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
                .param("languageCode", "en")
                .param("theme", "light")
                .param("emailNotifications", "true")
                .param("pushNotifications", "true"))
                .andExpect(status().is3xxRedirection())
                .andExpect(view().name("redirect:/admin/settings?saved=true"));
    }

    @Test
    void updateTheme_quickToggle_persistsTheme() throws Exception {
        mockMvc.perform(post("/admin/settings/theme")
                .with(user(adminUser.getEmail()).roles("ADMIN"))
                .with(csrf())
                .param("theme", "light"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.theme").value("light"));

        UserSetting setting = settingRepository.findByUserUserId(adminUser.getUserId()).orElse(null);
        assertThat(setting).isNotNull();
        assertThat(setting.getTheme()).isEqualTo("light");
    }

    @Test
    void updateTheme_invalidTheme_returnsBadRequest() throws Exception {
        mockMvc.perform(post("/admin/settings/theme")
                .with(user(adminUser.getEmail()).roles("ADMIN"))
                .with(csrf())
                .param("theme", "neon-blue"))
                .andExpect(status().isBadRequest());
    }

    @Test
    void nutrientsPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/nutrients")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/nutrients"));
    }

    @Test
    void tagsPage_loadsSuccessfully() throws Exception {
        com.nhamhealth.nhamhealth_api.entity.TagType t = new com.nhamhealth.nhamhealth_api.entity.TagType();
        t.setTagName("Test Tag " + System.currentTimeMillis());
        t.setTagScope("NUTRITION");
        t.setDescription("Test Description");
        t.setIsActive(true);
        tagTypeRepository.saveAndFlush(t);

        mockMvc.perform(get("/admin/tags")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/tags"));
    }

    @Test
    void servingSizesPage_loadsSuccessfully() throws Exception {
        com.nhamhealth.nhamhealth_api.entity.ServingSize s = new com.nhamhealth.nhamhealth_api.entity.ServingSize();
        s.setServingSizeName("Test Portion " + System.currentTimeMillis());
        s.setMultiplier(new java.math.BigDecimal("1.5"));
        s.setDescription("Test Portion Description");
        s.setIsActive(true);
        servingSizeRepository.saveAndFlush(s);

        mockMvc.perform(get("/admin/serving-sizes")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/serving-size"));
    }

    @Test
    void mealsPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/meals")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/meals"));
    }

    @Test
    void mealCategoriesPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/meal-categories")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/meal-categories"));
    }

    @Test
    void ingredientsPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/ingredients")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/ingredients"));
    }

    @Test
    void communityRecipesPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/community-recipes")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/community-recipes"));
    }

    @Test
    void aiFoodAnalysesPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/ai-food-analyses")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/ai-food-analysis"));
    }

    @Test
    void aiFoodSuggestionsPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/ai-food-suggestions")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/ai-food-suggestion"));
    }

    @Test
    void aiRecommendationsPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/ai-recommendations")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/ai-recommendation"));
    }

    @Test
    void dailyWellnessPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/daily-wellness")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/daily-wellness"));
    }

    @Test
    void usersPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/users")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/users"));
    }

    @Test
    void notificationsPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/notifications")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/notification"));
    }

    @Test
    void followsPage_loadsSuccessfully() throws Exception {
        mockMvc.perform(get("/admin/follows")
                .with(user(adminUser.getEmail()).roles("ADMIN")))
                .andExpect(status().isOk())
                .andExpect(view().name("admin/follows"));
    }
}
