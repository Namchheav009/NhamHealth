package com.nhamhealth.nhamhealth_api.controller.admin;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class SettingAdminController {

    @GetMapping("/admin/settings")
    public String settingsPage(Authentication authentication, Model model) {
        model.addAttribute("pageTitle", "Settings");
        model.addAttribute("activePage", "settings");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        return "admin/setting";
    }
}
