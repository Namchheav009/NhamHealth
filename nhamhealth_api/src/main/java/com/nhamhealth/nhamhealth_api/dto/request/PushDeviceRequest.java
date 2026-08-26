package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record PushDeviceRequest(
        @NotBlank @Size(max = 512) String token,
        @NotBlank @Size(max = 20) String platform) {
}
