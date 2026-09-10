package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.*;

public record AppealRequest(
    @NotNull Integer moderationActionId,
    @NotBlank 
    @Size(max = 500) String reason) {}
