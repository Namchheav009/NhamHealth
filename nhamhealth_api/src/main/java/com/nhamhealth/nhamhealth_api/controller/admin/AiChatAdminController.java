package com.nhamhealth.nhamhealth_api.controller.admin;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.AiChatConversation;
import com.nhamhealth.nhamhealth_api.entity.AiChatMessage;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiChatConversationRepository;
import com.nhamhealth.nhamhealth_api.repository.AiChatMessageRepository;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class AiChatAdminController {
    private final AiChatConversationRepository conversationRepository;
    private final AiChatMessageRepository messageRepository;
    private final UserRepository userRepository;
    private final MoodRepository moodRepository;

    public AiChatAdminController(AiChatConversationRepository conversationRepository,
            AiChatMessageRepository messageRepository, UserRepository userRepository, MoodRepository moodRepository) {
        this.conversationRepository = conversationRepository;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.moodRepository = moodRepository;
    }

    @GetMapping("/admin/ai-chat")
    public String aiChatPage(Authentication authentication, Model model) {
        List<AiChatConversation> conversations = conversationRepository.findAllByOrderByUpdatedAtDesc();
        model.addAttribute("pageTitle", "AI Chat");
        model.addAttribute("activePage", "ai-chat");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("chatThreads", conversations);
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("moods", moodRepository.findAllByOrderByMoodNameAsc());
        model.addAttribute("messageCounts", conversations.stream().collect(Collectors.toMap(
                AiChatConversation::getAiConversationId,
                conversation -> messageRepository.countByAiChatConversationAiConversationId(conversation.getAiConversationId()))));
        model.addAttribute("lastMessages", conversations.stream().collect(Collectors.toMap(
                AiChatConversation::getAiConversationId,
                conversation -> messageRepository
                        .findTopByAiChatConversationAiConversationIdOrderByCreatedAtDesc(conversation.getAiConversationId())
                        .map(AiChatMessage::getMessageText).orElse("No messages"))));
        model.addAttribute("totalThreads", conversations.size());
        model.addAttribute("activeThreads", conversationRepository.countByIsActiveTrue());
        model.addAttribute("totalMessages", messageRepository.count());
        return "admin/ai-chat";
    }

    @PostMapping("/admin/ai-chat")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> createConversation(@RequestParam Integer userId,
            @RequestParam(required = false) Integer moodId, @RequestParam String title,
            @RequestParam(required = false) String prompt) {
        User user = userRepository.findById(userId).orElse(null);
        Mood mood = moodId == null ? null : moodRepository.findById(moodId).orElse(null);
        if (user == null) return ResponseEntity.badRequest().body(Map.of("message", "Select a valid user."));
        if (moodId != null && mood == null) return ResponseEntity.badRequest().body(Map.of("message", "Select a valid mood."));
        if (title == null || title.isBlank()) return ResponseEntity.badRequest().body(Map.of("message", "Conversation title is required."));
        LocalDateTime now = LocalDateTime.now();
        AiChatConversation conversation = new AiChatConversation();
        conversation.setUser(user);
        conversation.setCurrentMood(mood);
        conversation.setTitle(title.trim());
        conversation.setIsActive(true);
        conversation.setCreatedAt(now);
        conversation.setUpdatedAt(now);
        conversation = conversationRepository.saveAndFlush(conversation);
        int messageCount = 0;
        String lastMessage = "No messages";
        if (prompt != null && !prompt.isBlank()) {
            AiChatMessage message = new AiChatMessage();
            message.setAiChatConversation(conversation);
            message.setSenderType("USER");
            message.setMessageText(prompt.trim());
            message.setCreatedAt(now);
            messageRepository.save(message);
            messageCount = 1;
            lastMessage = prompt.trim();
        }
        return ResponseEntity.ok(toResponse(conversation, messageCount, lastMessage));
    }

    @PatchMapping("/admin/ai-chat/{conversationId}/active")
    @ResponseBody
    public ResponseEntity<?> updateActive(@PathVariable Integer conversationId, @RequestParam boolean active) {
        AiChatConversation conversation = conversationRepository.findById(conversationId).orElse(null);
        if (conversation == null) return ResponseEntity.notFound().build();
        conversation.setIsActive(active);
        conversation.setUpdatedAt(LocalDateTime.now());
        conversationRepository.saveAndFlush(conversation);
        return ResponseEntity.ok(Map.of("active", active, "updatedAt", conversation.getUpdatedAt().toString()));
    }

    @DeleteMapping("/admin/ai-chat/{conversationId}")
    @ResponseBody
    @Transactional
    public ResponseEntity<Void> deleteConversation(@PathVariable Integer conversationId) {
        if (!conversationRepository.existsById(conversationId)) return ResponseEntity.notFound().build();
        messageRepository.deleteByAiChatConversationAiConversationId(conversationId);
        conversationRepository.deleteById(conversationId);
        return ResponseEntity.noContent().build();
    }

    private Map<String, Object> toResponse(AiChatConversation conversation, int messageCount, String lastMessage) {
        User user = conversation.getUser();
        String name = user.getName() == null || user.getName().isBlank() ? "Unknown user" : user.getName();
        return Map.ofEntries(
                Map.entry("id", conversation.getAiConversationId()), Map.entry("userId", user.getUserId()),
                Map.entry("userName", name), Map.entry("userEmail", user.getEmail() == null ? "" : user.getEmail()),
                Map.entry("title", conversation.getTitle()),
                Map.entry("mood", conversation.getCurrentMood() == null ? "" : conversation.getCurrentMood().getMoodName()),
                Map.entry("active", conversation.getIsActive()), Map.entry("messageCount", messageCount),
                Map.entry("lastMessage", lastMessage), Map.entry("updatedAt", conversation.getUpdatedAt().toString()));
    }
}
