package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;

import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;

import com.nhamhealth.nhamhealth_api.entity.Chat;
import com.nhamhealth.nhamhealth_api.repository.ChatRepository;

@Controller
public class ChatAdminController {

    private final ChatRepository chatRepository;

    public ChatAdminController(ChatRepository chatRepository) {
        this.chatRepository = chatRepository;
    }

    @GetMapping("/admin/chats")
    public String chatsPage(Authentication authentication, Model model) {
        List<Chat> chats = chatRepository.findAll();
        model.addAttribute("pageTitle", "Chats");
        model.addAttribute("activePage", "chats");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("chats", chats);
        model.addAttribute("totalChats", chats.size());
        return "admin/chat";
    }
}
