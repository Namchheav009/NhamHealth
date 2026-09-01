package com.nhamhealth.nhamhealth_api.controller.api;

import static org.springframework.http.HttpStatus.SERVICE_UNAVAILABLE;
import static org.springframework.http.HttpStatus.UNAUTHORIZED;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.ai.AssistantChatRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AssistantChatResponse;
import com.nhamhealth.nhamhealth_api.service.ai.AiAssistantService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/v1/ai-assistant")
public class AiAssistantApiController {
    private final AiAssistantService assistantService;

    public AiAssistantApiController(AiAssistantService assistantService) {
        this.assistantService = assistantService;
    }

    @PostMapping("/chat")
    public ResponseEntity<AssistantChatResponse> chat(
            @AuthenticationPrincipal Jwt jwt,
            @Valid @RequestBody AssistantChatRequest request) {
        if (jwt == null) throw new ResponseStatusException(UNAUTHORIZED, "Authentication is required.");
        Number userId = jwt.getClaim("userId");
        if (userId == null) throw new ResponseStatusException(UNAUTHORIZED, "The access token has no user ID.");
        try {
            return ResponseEntity.ok(new AssistantChatResponse(
                    assistantService.chat(userId.intValue(), request)));
        } catch (RuntimeException error) {
            throw new ResponseStatusException(SERVICE_UNAVAILABLE, error.getMessage(), error);
        }
    }
}
