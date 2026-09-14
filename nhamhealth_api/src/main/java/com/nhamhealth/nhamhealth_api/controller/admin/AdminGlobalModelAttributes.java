package com.nhamhealth.nhamhealth_api.controller.admin;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

import com.nhamhealth.nhamhealth_api.repository.notification.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserSettingRepository;

@ControllerAdvice(basePackages = "com.nhamhealth.nhamhealth_api.controller.admin")
public class AdminGlobalModelAttributes {

    private static final Logger log = LoggerFactory.getLogger(AdminGlobalModelAttributes.class);

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;
    private final UserSettingRepository settingRepository;

    public AdminGlobalModelAttributes(NotificationRepository notificationRepository, UserRepository userRepository,
            UserSettingRepository settingRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
        this.settingRepository = settingRepository;
    }

    @ModelAttribute
    public void addAdminName(Model model) {
        String adminName = resolveAdminName();
        model.addAttribute("adminName", adminName);
        model.addAttribute("globalUnreadNotificationCount", 0L);
        model.addAttribute("globalUnreadReportCount", 0L);
        model.addAttribute("adminTheme", "system");

        if ("Admin".equalsIgnoreCase(adminName)) {
            return;
        }

        try {
            userRepository.findByEmailIgnoreCase(adminName).ifPresent(admin -> {
                try {
                    model.addAttribute("globalUnreadNotificationCount",
                            notificationRepository.countByUserUserIdAndIsReadFalse(admin.getUserId()));
                } catch (Exception ex) {
                    log.debug("Failed to count unread notifications: {}", ex.getMessage());
                }
                try {
                    model.addAttribute("globalUnreadReportCount", notificationRepository
                            .countByUserUserIdAndNotificationTypeIgnoreCaseAndIsReadFalse(admin.getUserId(), "REPORT"));
                } catch (Exception ex) {
                    log.debug("Failed to count unread reports: {}", ex.getMessage());
                }
                try {
                    String theme = settingRepository.findByUserUserId(admin.getUserId())
                            .map(com.nhamhealth.nhamhealth_api.entity.UserSetting::getTheme)
                            .orElse("system");
                    model.addAttribute("adminTheme", theme != null && !theme.isBlank() ? theme : "system");
                } catch (Exception ex) {
                    log.debug("Failed to fetch user theme setting: {}", ex.getMessage());
                }
            });
        } catch (Exception ex) {
            log.warn("Failed to load admin global attributes for {}: {}", adminName, ex.getMessage());
        }
    }

    private String resolveAdminName() {
        try {
            Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
            if (authentication != null && authentication.getName() != null && !authentication.getName().isBlank()
                    && !"anonymousUser".equalsIgnoreCase(authentication.getName())) {
                return authentication.getName();
            }
        } catch (Exception ignored) {
        }
        return "Admin";
    }
}
