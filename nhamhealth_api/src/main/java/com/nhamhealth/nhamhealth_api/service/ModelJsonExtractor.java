package com.nhamhealth.nhamhealth_api.service;

/** Extracts one complete JSON object from common model response wrappers. */
final class ModelJsonExtractor {
    private ModelJsonExtractor() {}

    static String extractObject(String content) {
        if (content == null || content.isBlank()) {
            throw new IllegalArgumentException("The model returned empty content.");
        }
        String cleaned = content.replaceFirst("(?s)^\\s*```(?:json)?\\s*", "")
                .replaceFirst("(?s)\\s*```\\s*$", "").trim();
        int start = cleaned.indexOf('{');
        int end = cleaned.lastIndexOf('}');
        if (start < 0 || end < start) {
            throw new IllegalArgumentException("The model returned an incomplete JSON object.");
        }
        return cleaned.substring(start, end + 1);
    }
}
