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
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.Chat;
import com.nhamhealth.nhamhealth_api.entity.ChatParticipant;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.ChatParticipantRepository;
import com.nhamhealth.nhamhealth_api.repository.ChatRepository;
import com.nhamhealth.nhamhealth_api.repository.MessageRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class ChatAdminController {

    private final ChatRepository chatRepository;
    private final ChatParticipantRepository participantRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;

    public ChatAdminController(ChatRepository chatRepository, ChatParticipantRepository participantRepository,
            MessageRepository messageRepository, UserRepository userRepository) {
        this.chatRepository = chatRepository;
        this.participantRepository = participantRepository;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
    }

    @GetMapping("/admin/chats")
    public String chatsPage(Authentication authentication, Model model) {
        List<Chat> chats = chatRepository.findAllByOrderByLastMessageAtDescCreatedAtDesc();
        List<Integer> chatIds = chats.stream().map(Chat::getChatId).toList();
        Map<Integer, Long> participantCounts = chatIds.stream()
                .collect(Collectors.toMap(id -> id, ignored -> 0L));
        if (!chatIds.isEmpty()) {
            participantRepository.countActiveByChatIds(chatIds)
                    .forEach(count -> participantCounts.put(count.getChatId(), count.getTotal()));
        }
        Map<Integer, Long> messageCounts = chatIds.stream()
                .collect(Collectors.toMap(id -> id, ignored -> 0L));
        if (!chatIds.isEmpty()) {
            messageRepository.countActiveByChatIds(chatIds)
                    .forEach(count -> messageCounts.put(count.getChatId(), count.getTotal()));
        }
        model.addAttribute("pageTitle", "Chats");
        model.addAttribute("activePage", "chats");
        model.addAttribute("adminName", authentication != null ? authentication.getName() : "admin");
        model.addAttribute("chats", chats);
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("participantCounts", participantCounts);
        model.addAttribute("messageCounts", messageCounts);
        model.addAttribute("totalChats", chats.size());
        model.addAttribute("activeUsers", participantRepository.countActiveUsers());
        model.addAttribute("recentMessages",
                messageRepository.countByCreatedAtGreaterThanEqualAndDeletedAtIsNull(LocalDateTime.now().minusHours(24)));
        return "admin/chat";
    }

    @PostMapping("/admin/chats")
    @ResponseBody
    @Transactional
    public ResponseEntity<?> createChat(@RequestParam(required = false) String chatName,
            @RequestParam String chatType, @RequestParam(required = false) List<Integer> participantIds) {
        String type = chatType == null ? "" : chatType.trim().toLowerCase();
        if (!List.of("direct", "group").contains(type)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select a valid chat type."));
        }
        List<Integer> distinctIds = participantIds == null ? List.of() : participantIds.stream().distinct().toList();
        if (type.equals("direct") && distinctIds.size() != 2) {
            return ResponseEntity.badRequest().body(Map.of("message", "A direct chat requires exactly two users."));
        }
        if (type.equals("group") && distinctIds.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select at least one group participant."));
        }
        List<User> participants = userRepository.findAllById(distinctIds);
        if (participants.size() != distinctIds.size()) {
            return ResponseEntity.badRequest().body(Map.of("message", "One or more selected users no longer exist."));
        }
        LocalDateTime now = LocalDateTime.now();
        String cleanName = chatName == null ? "" : chatName.trim();
        if (type.equals("group") && cleanName.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "Enter a name for the group chat."));
        }
        if (cleanName.isBlank()) cleanName = participants.stream().map(User::getName).collect(Collectors.joining(" & "));

        Chat chat = new Chat();
        chat.setChatType(type);
        chat.setChatName(cleanName);
        chat.setCreatedAt(now);
        chat.setUpdatedAt(now);
        chat = chatRepository.saveAndFlush(chat);
        for (User user : participants) {
            ChatParticipant participant = new ChatParticipant();
            participant.setChat(chat);
            participant.setUser(user);
            participant.setJoinedAt(now);
            participantRepository.save(participant);
        }
        return ResponseEntity.ok(Map.ofEntries(
                Map.entry("id", chat.getChatId()), Map.entry("chatName", chat.getChatName()),
                Map.entry("chatType", chat.getChatType()), Map.entry("participantCount", participants.size()),
                Map.entry("messageCount", 0), Map.entry("createdAt", chat.getCreatedAt().toString()),
                Map.entry("lastMessageAt", "")));
    }
}
