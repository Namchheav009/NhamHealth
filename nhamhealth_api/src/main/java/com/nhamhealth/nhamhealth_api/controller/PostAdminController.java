package com.nhamhealth.nhamhealth_api.controller;

import java.util.Collections;
import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class PostAdminController {

    @GetMapping("/admin/posts")
    public String postsPage(Authentication authentication, Model model) {
        List<Object> posts = Collections.emptyList();
        model.addAttribute("pageTitle", "Posts");
        model.addAttribute("activePage", "posts");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("posts", posts);
        model.addAttribute("totalPosts", posts.size());
        return "admin/post";
    }
}
