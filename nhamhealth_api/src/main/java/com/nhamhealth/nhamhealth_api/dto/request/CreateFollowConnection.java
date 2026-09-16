package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public record CreateFollowConnection(
        @NotNull(message = "receiverId is required")
        @Positive(message = "receiverId must be positive")
        Integer receiverId) { }
