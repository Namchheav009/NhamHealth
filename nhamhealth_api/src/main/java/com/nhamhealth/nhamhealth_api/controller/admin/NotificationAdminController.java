package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.Notification;
import com.nhamhealth.nhamhealth_api.repository.NotificationRepository;

@Controller
public class NotificationAdminController {

    private final NotificationRepository notificationRepository;

    public NotificationAdminController(NotificationRepository notificationRepository) {
        this.notificationRepository = notificationRepository;
    }

    @GetMapping("/admin/notifications")
    public String notificationsPage(Authentication authentication, Model model) {
        List<Notification> notifs = notificationRepository.findAll();
        model.addAttribute("pageTitle", "Notifications");
        model.addAttribute("activePage", "notifications");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("notifications", notifs);
        model.addAttribute("totalNotifications", notifs.size());
        return "admin/notification";
    }
}
