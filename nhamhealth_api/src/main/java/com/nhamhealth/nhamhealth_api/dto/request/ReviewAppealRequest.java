package com.nhamhealth.nhamhealth_api.dto.request;

import com.nhamhealth.nhamhealth_api.entity.AppealStatus;
import jakarta.validation.constraints.*;

public record ReviewAppealRequest(
    @NotNull AppealStatus status, 
    @Size(max = 1000) 
    String adminNote) {}
