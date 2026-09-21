package com.nhamhealth.nhamhealth_api.dto.ai;

import java.time.LocalDate;
import java.util.List;

import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AssistantChatRequest(
                @NotBlank @Size(max = 2_000) String message,
                LocalDate date,
                @Size(max = 50) String timezone,
                @Size(max = 5) String localTime,
                @Size(max = 12) List<@Valid Message> history) {

        public record Message(
                        @NotBlank String role,
                        @NotBlank @Size(max = 2_000) String content) {
        }
}
