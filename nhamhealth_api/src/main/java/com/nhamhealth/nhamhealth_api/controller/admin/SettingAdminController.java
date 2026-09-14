package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserSetting;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserSettingRepository;

@Controller
public class SettingAdminController {
    private static final List<String> LANGUAGES = List.of("en", "km");
    private static final List<String> THEMES = List.of("light", "dark", "system");
    private final UserRepository userRepository;
    private final UserSettingRepository settingRepository;

    public SettingAdminController(UserRepository userRepository, UserSettingRepository settingRepository) {
        this.userRepository = userRepository;
        this.settingRepository = settingRepository;
    }

    @GetMapping("/admin/settings")
    public String settingsPage(Authentication authentication, Model model) {
        String email = authentication != null ? authentication.getName() : "";
        User user = userRepository.findByEmailIgnoreCase(email).orElse(null);
        UserSetting setting = user == null ? null : settingRepository.findByUserUserId(user.getUserId()).orElse(null);
        model.addAttribute("pageTitle", "Settings");
        model.addAttribute("activePage", "settings");
        model.addAttribute("adminName", email.isBlank() ? "admin" : email);
        model.addAttribute("accountEmail", user == null ? email : user.getEmail());
        model.addAttribute("accountRole", user == null ? "ADMIN" : user.getRoleLabel());
        model.addAttribute("languageCode", setting == null ? "en" : setting.getLanguageCode());
        model.addAttribute("theme", setting == null ? "system" : setting.getTheme());
        model.addAttribute("emailNotifications", setting == null || Boolean.TRUE.equals(setting.getEmailNotificationsEnabled()));
        model.addAttribute("pushNotifications", setting == null || Boolean.TRUE.equals(setting.getPushNotificationsEnabled()));
        model.addAttribute("lastUpdated", setting == null ? null : setting.getUpdatedAt());
        return "admin/setting";
    }

    @PostMapping("/admin/settings")
    public Object saveSettings(Authentication authentication,
            @RequestHeader(value = "Accept", defaultValue = "") String acceptHeader,
            @RequestHeader(value = "X-Requested-With", defaultValue = "") String requestedWith,
            @RequestParam String languageCode,
            @RequestParam String theme,
            @RequestParam boolean emailNotifications,
            @RequestParam boolean pushNotifications) {
        boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(requestedWith)
                || (acceptHeader != null && acceptHeader.contains(org.springframework.http.MediaType.APPLICATION_JSON_VALUE));

        if (authentication == null) {
            return isAjax
                    ? ResponseEntity.status(401).contentType(org.springframework.http.MediaType.APPLICATION_JSON).body(Map.of("message", "Sign in again to save settings."))
                    : "redirect:/login";
        }
        User user = userRepository.findByEmailIgnoreCase(authentication.getName()).orElse(null);
        if (user == null) {
            return isAjax
                    ? ResponseEntity.badRequest().contentType(org.springframework.http.MediaType.APPLICATION_JSON).body(Map.of("message", "The signed-in admin account was not found."))
                    : "redirect:/admin/settings?error=not_found";
        }
        String language = languageCode != null ? languageCode.trim().toLowerCase() : "en";
        String selectedTheme = theme != null ? theme.trim().toLowerCase() : "system";
        if (!LANGUAGES.contains(language) || !THEMES.contains(selectedTheme)) {
            return isAjax
                    ? ResponseEntity.badRequest().contentType(org.springframework.http.MediaType.APPLICATION_JSON).body(Map.of("message", "Select a supported language and theme."))
                    : "redirect:/admin/settings?error=invalid";
        }
        LocalDateTime now = LocalDateTime.now();
        UserSetting setting = settingRepository.findByUserUserId(user.getUserId()).orElseGet(() -> {
            UserSetting created = new UserSetting();
            created.setUser(user);
            created.setCreatedAt(now);
            return created;
        });
        setting.setLanguageCode(language);
        setting.setTheme(selectedTheme);
        setting.setEmailNotificationsEnabled(emailNotifications);
        setting.setPushNotificationsEnabled(pushNotifications);
        setting.setUpdatedAt(now);
        settingRepository.saveAndFlush(setting);

        if (!isAjax) {
            return "redirect:/admin/settings?saved=true";
        }
        return ResponseEntity.ok()
                .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                .body(Map.of("message", "Your preferences were saved.", "updatedAt", now.toString()));
    }

    @PostMapping(value = "/admin/settings/theme", produces = "application/json")
    @ResponseBody
    public ResponseEntity<?> updateTheme(Authentication authentication, @RequestParam String theme) {
        if (authentication == null) {
            return ResponseEntity.status(401)
                    .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                    .body(Map.of("message", "Sign in again to save settings."));
        }
        User user = userRepository.findByEmailIgnoreCase(authentication.getName()).orElse(null);
        if (user == null) {
            return ResponseEntity.badRequest()
                    .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                    .body(Map.of("message", "The signed-in admin account was not found."));
        }
        String selectedTheme = theme != null ? theme.trim().toLowerCase() : "system";
        if (!THEMES.contains(selectedTheme)) {
            return ResponseEntity.badRequest()
                    .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                    .body(Map.of("message", "Select a supported theme."));
        }
        LocalDateTime now = LocalDateTime.now();
        UserSetting setting = settingRepository.findByUserUserId(user.getUserId()).orElseGet(() -> {
            UserSetting created = new UserSetting();
            created.setUser(user);
            created.setLanguageCode("en");
            created.setEmailNotificationsEnabled(true);
            created.setPushNotificationsEnabled(true);
            created.setCreatedAt(now);
            return created;
        });
        setting.setTheme(selectedTheme);
        setting.setUpdatedAt(now);
        settingRepository.saveAndFlush(setting);
        return ResponseEntity.ok()
                .contentType(org.springframework.http.MediaType.APPLICATION_JSON)
                .body(Map.of("message", "Theme updated.", "theme", selectedTheme));
    }
}
