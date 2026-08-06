package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.Collections;
import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class ReportAdminController {

    @GetMapping("/admin/reports")
    public String reportsPage(Authentication authentication, Model model) {
        List<Object> reports = Collections.emptyList();
        model.addAttribute("pageTitle", "Reports");
        model.addAttribute("activePage", "reports");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("reports", reports);
        model.addAttribute("totalReports", reports.size());
        return "admin/report";
    }
}
