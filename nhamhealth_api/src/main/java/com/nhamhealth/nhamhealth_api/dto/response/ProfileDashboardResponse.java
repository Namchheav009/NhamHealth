package com.nhamhealth.nhamhealth_api.dto.response;

import java.math.BigDecimal;

public record ProfileDashboardResponse(
        Integer userId,
        String email,
        String fullName,
        String profileImageUrl,
        String membership,
        String phone,
        java.time.LocalDate dateOfBirth,
        String gender,
        Integer age,
        BigDecimal heightCm,
        BigDecimal weightKg,
        Progress calories,
        Progress protein,
        Progress water,
        Progress fiber,
        Progress sugar,
        String insight) {

    public record Progress(BigDecimal current, BigDecimal goal) {
    }
}
