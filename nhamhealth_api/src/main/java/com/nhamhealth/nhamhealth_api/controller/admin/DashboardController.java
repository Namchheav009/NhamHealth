package com.nhamhealth.nhamhealth_api.controller.admin;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.service.AdminDashboardService;
import com.nhamhealth.nhamhealth_api.service.AdminDashboardService.DashboardSnapshot;

@Controller
public class DashboardController {

    private final AdminDashboardService adminDashboardService;

    public DashboardController(AdminDashboardService adminDashboardService) {
        this.adminDashboardService = adminDashboardService;
    }

    @GetMapping("/")
    public String home() {
        return "redirect:/dashboard";
    }

    @GetMapping("/dashboard")
    public String dashboard(Authentication authentication, Model model) {
        String adminName = authentication != null ? authentication.getName() : "Admin";
        model.addAttribute("email", adminName);
        model.addAttribute("adminName", adminName);
        model.addAttribute("pageTitle", "Dashboard");
        DashboardSnapshot dashboard = adminDashboardService.loadDashboard();
        model.addAttribute("dashboard", dashboard);
        model.addAttribute("activityLabels", dashboard.activity().stream().map(point -> point.label()).toList());
        model.addAttribute("activityUsers", dashboard.activity().stream().map(point -> point.newUsers()).toList());
        model.addAttribute("activityMealLogs", dashboard.activity().stream().map(point -> point.mealLogs()).toList());
        model.addAttribute("categoryLabels", dashboard.categories().stream().map(category -> category.name()).toList());
        model.addAttribute("categoryValues", dashboard.categories().stream().map(category -> category.count()).toList());
        return "admin/dashboard";
    }

    @GetMapping("/admin/dashboard")
    public String adminDashboard(Authentication authentication, Model model) {
        return dashboard(authentication, model);
    }
}
