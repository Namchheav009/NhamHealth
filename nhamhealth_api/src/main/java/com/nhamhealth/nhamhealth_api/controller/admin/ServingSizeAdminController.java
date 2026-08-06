package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.ServingSize;
import com.nhamhealth.nhamhealth_api.repository.ServingSizeRepository;

@Controller
public class ServingSizeAdminController {

    private final ServingSizeRepository servingSizeRepository;

    public ServingSizeAdminController(ServingSizeRepository servingSizeRepository) {
        this.servingSizeRepository = servingSizeRepository;
    }

    @GetMapping("/admin/serving-sizes")
    public String servingSizes(Model model) {
        List<ServingSize> servingSizes = servingSizeRepository.findAllByOrderByServingSizeNameAsc();
        int total = servingSizes.size();
        long active = servingSizes.stream().filter(s -> Boolean.TRUE.equals(s.getIsActive())).count();
        long inactive = total - active;
        long weightBased = servingSizes.stream().filter(s -> isWeightBased(s.getServingSizeName())).count();
        long volumeBased = total - weightBased;

        model.addAttribute("pageTitle", "Serving Sizes");
        model.addAttribute("servingSizes", servingSizes);
        model.addAttribute("totalServingSizes", total);
        model.addAttribute("activeServingSizes", active);
        model.addAttribute("inactiveServingSizes", inactive);
        model.addAttribute("weightBased", weightBased);
        model.addAttribute("volumeBased", volumeBased);

        return "admin/serving-size";
    }

    private boolean isWeightBased(String name) {
        if (name == null)
            return false;
        String n = name.toLowerCase();
        return n.contains("gram") || n.matches(".*\\b g\\b.*") || n.contains("kg") || n.contains("ounce")
                || n.contains("oz") || n.contains("grams");
    }
}
