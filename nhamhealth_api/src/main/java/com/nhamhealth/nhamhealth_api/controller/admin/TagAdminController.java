package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.TagType;
import com.nhamhealth.nhamhealth_api.repository.TagTypeRepository;

@Controller
public class TagAdminController {

    private final TagTypeRepository tagTypeRepository;

    public TagAdminController(TagTypeRepository tagTypeRepository) {
        this.tagTypeRepository = tagTypeRepository;
    }

    @GetMapping("/admin/tags")
    public String tags(Authentication authentication, Model model) {
        List<TagType> tags = tagTypeRepository.findAllByOrderByTagNameAsc();

        long activeTags = tags.stream()
                .filter(tag -> Boolean.TRUE.equals(tag.getIsActive()))
                .count();

        model.addAttribute("pageTitle", "Tags");
        model.addAttribute("activePage", "tags");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("tags", tags);
        model.addAttribute("totalTags", tags.size());
        model.addAttribute("activeTags", activeTags);
        model.addAttribute("inactiveTags", Math.max(0, tags.size() - activeTags));
        return "admin/tags";
    }
}
