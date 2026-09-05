package com.nhamhealth.nhamhealth_api.dto.request;

import jakarta.validation.constraints.NotBlank;

public record SendPhoneCodeRequest(
        @NotBlank(message = "Phone number is required")
        String phone
        ) {

}
