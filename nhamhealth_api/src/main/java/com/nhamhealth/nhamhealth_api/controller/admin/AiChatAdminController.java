package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.Collections;
import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class AiChatAdminController {

    @GetMapping("/admin/ai-chat")
    public String aiChatPage(Authentication authentication, Model model) {
        // For now, serve an empty list of chats — repository can be added later.
        List<Object> chats = Collections.emptyList();

        model.addAttribute("pageTitle", "AI Chat");
        model.addAttribute("activePage", "ai-chat");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("chatThreads", chats);
        model.addAttribute("totalThreads", chats.size());

        return "admin/ai-chat";
    }
}
