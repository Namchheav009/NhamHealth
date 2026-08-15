package com.nhamhealth.nhamhealth_api.controller.admin;

import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.time.LocalDateTime;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Controller;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

import com.nhamhealth.nhamhealth_api.entity.AiRecommendation;
import com.nhamhealth.nhamhealth_api.entity.Mood;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.AiRecommendationItemRepository;
import com.nhamhealth.nhamhealth_api.repository.AiRecommendationRepository;
import com.nhamhealth.nhamhealth_api.repository.MoodRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Controller
public class AiRecommendationAdminController {

    private final AiRecommendationRepository aiRecommendationRepository;
    private final AiRecommendationItemRepository itemRepository;
    private final UserRepository userRepository;
    private final MoodRepository moodRepository;

    public AiRecommendationAdminController(AiRecommendationRepository aiRecommendationRepository,
            AiRecommendationItemRepository itemRepository, UserRepository userRepository,
            MoodRepository moodRepository) {
        this.aiRecommendationRepository = aiRecommendationRepository;
        this.itemRepository = itemRepository;
        this.userRepository = userRepository;
        this.moodRepository = moodRepository;
    }

    @GetMapping("/admin/ai-recommendations")
    public String aiRecommendationsPage(Authentication authentication, Model model) {
        List<AiRecommendation> recs = aiRecommendationRepository.findAllByOrderByCreatedAtDesc();

        long uniqueUsers = recs.stream()
                .map(r -> r.getUser() != null ? r.getUser().getUserId() : null)
                .filter(Objects::nonNull)
                .distinct()
                .count();

        model.addAttribute("pageTitle", "AI Recommendations");
        model.addAttribute("activePage", "ai-recommendations");
        model.addAttribute("adminName", authentication.getName());
        model.addAttribute("aiRecs", recs);
        model.addAttribute("users", userRepository.findAll());
        model.addAttribute("moods", moodRepository.findAllByOrderByMoodNameAsc());
        model.addAttribute("itemCounts", recs.stream().collect(java.util.stream.Collectors.toMap(
                AiRecommendation::getRecommendationId,
                rec -> itemRepository.countByRecommendationRecommendationId(rec.getRecommendationId()))));
        model.addAttribute("totalRecs", recs.size());
        model.addAttribute("uniqueUsers", uniqueUsers);
        model.addAttribute("totalItems", itemRepository.count());

        return "admin/ai-recommendation";
    }

    @PostMapping("/admin/ai-recommendations")
    @ResponseBody
    public ResponseEntity<?> createRecommendation(@RequestParam Integer userId,
            @RequestParam(required = false) Integer moodId, @RequestParam String requestText,
            @RequestParam(required = false) String responseText, @RequestParam String status) {
        if (requestText == null || requestText.isBlank() || status == null || status.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("message", "User, request, and status are required."));
        }
        User user = userRepository.findById(userId).orElse(null);
        if (user == null) return ResponseEntity.badRequest().body(Map.of("message", "Select a valid user."));
        Mood mood = moodId == null ? null : moodRepository.findById(moodId).orElse(null);
        if (moodId != null && mood == null) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select a valid mood."));
        }
        String normalizedStatus = status.trim().toLowerCase();
        if (!List.of("pending", "ready", "archived").contains(normalizedStatus)) {
            return ResponseEntity.badRequest().body(Map.of("message", "Select a valid status."));
        }
        LocalDateTime now = LocalDateTime.now();
        AiRecommendation rec = new AiRecommendation();
        rec.setUser(user);
        rec.setMood(mood);
        rec.setRequestText(requestText.trim());
        rec.setResponseText(responseText == null || responseText.isBlank() ? null : responseText.trim());
        rec.setStatus(normalizedStatus);
        rec.setCreatedAt(now);
        rec.setUpdatedAt(now);
        return ResponseEntity.ok(toResponse(aiRecommendationRepository.saveAndFlush(rec)));
    }

    @DeleteMapping("/admin/ai-recommendations/{recommendationId}")
    @ResponseBody
    @Transactional
    public ResponseEntity<Void> deleteRecommendation(@PathVariable Integer recommendationId) {
        if (!aiRecommendationRepository.existsById(recommendationId)) return ResponseEntity.notFound().build();
        itemRepository.deleteByRecommendationRecommendationId(recommendationId);
        aiRecommendationRepository.deleteById(recommendationId);
        return ResponseEntity.noContent().build();
    }

    private Map<String, Object> toResponse(AiRecommendation rec) {
        String userName = rec.getUser().getName();
        String userEmail = rec.getUser().getEmail();
        return Map.ofEntries(
                Map.entry("id", rec.getRecommendationId()),
                Map.entry("userId", rec.getUser().getUserId()),
                Map.entry("userName", userName == null || userName.isBlank() ? "Unknown user" : userName),
                Map.entry("userEmail", userEmail == null ? "" : userEmail),
                Map.entry("mood", rec.getMood() == null ? "" : rec.getMood().getMoodName()),
                Map.entry("requestText", rec.getRequestText()),
                Map.entry("responseText", rec.getResponseText() == null ? "" : rec.getResponseText()),
                Map.entry("status", rec.getStatus()),
                Map.entry("createdAt", rec.getCreatedAt().toString()),
                Map.entry("itemCount", 0));
    }
}
