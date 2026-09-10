package com.nhamhealth.nhamhealth_api.controller.admin;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

import com.nhamhealth.nhamhealth_api.repository.notification.NotificationRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;

@ControllerAdvice
public class AdminGlobalModelAttributes {

    private final NotificationRepository notificationRepository;
    private final UserRepository userRepository;

    public AdminGlobalModelAttributes(NotificationRepository notificationRepository, UserRepository userRepository) {
        this.notificationRepository = notificationRepository;
        this.userRepository = userRepository;
    }

    @ModelAttribute
    public void addAdminName(Model model) {
        String adminName = resolveAdminName();
        model.addAttribute("adminName", adminName);
        userRepository.findByEmailIgnoreCase(adminName).ifPresentOrElse(admin -> {
            model.addAttribute("globalUnreadNotificationCount",
                    notificationRepository.countByUserUserIdAndIsReadFalse(admin.getUserId()));
            model.addAttribute("globalUnreadReportCount", notificationRepository
                    .countByUserUserIdAndNotificationTypeIgnoreCaseAndIsReadFalse(admin.getUserId(), "REPORT"));
        }, () -> {
            model.addAttribute("globalUnreadNotificationCount", 0L);
            model.addAttribute("globalUnreadReportCount", 0L);
        });
    }

    private String resolveAdminName() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getName() != null && !authentication.getName().isBlank()) {
            return authentication.getName();
        }
        return "Admin";
    }
}
