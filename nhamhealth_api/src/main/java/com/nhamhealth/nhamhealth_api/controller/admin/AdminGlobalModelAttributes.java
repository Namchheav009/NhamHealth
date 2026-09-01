package com.nhamhealth.nhamhealth_api.controller.admin;

import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ModelAttribute;

import com.nhamhealth.nhamhealth_api.repository.notification.NotificationRepository;

@ControllerAdvice
public class AdminGlobalModelAttributes {

    private final NotificationRepository notificationRepository;

    public AdminGlobalModelAttributes(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @ModelAttribute
    public void addAdminName(Model model) {
        model.addAttribute("adminName", resolveAdminName());
        model.addAttribute("globalUnreadNotificationCount", notificationRepository.countByIsReadFalse());
    }

    private String resolveAdminName() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getName() != null && !authentication.getName().isBlank()) {
            return authentication.getName();
        }
        return "Admin";
    }
}
