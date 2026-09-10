package com.nhamhealth.nhamhealth_api.dto.request;

import java.time.LocalDateTime; 
import com.nhamhealth.nhamhealth_api.entity.ModerationActionType; 
import jakarta.validation.constraints.*;
public record ModerationActionRequest(
        @NotNull ModerationActionType actionType,
        @Size(max=1000) String adminNote,
        LocalDateTime startsAt,
        LocalDateTime expiresAt){
            
        }
