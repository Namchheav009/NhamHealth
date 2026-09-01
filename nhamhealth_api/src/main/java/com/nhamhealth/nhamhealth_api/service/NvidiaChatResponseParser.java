package com.nhamhealth.nhamhealth_api.service;

import com.fasterxml.jackson.databind.JsonNode;

/** Normalizes the response shapes returned by NVIDIA chat and reasoning models. */
final class NvidiaChatResponseParser {
    private NvidiaChatResponseParser() {}

    static String text(JsonNode message) {
        return flatten(message == null ? null : message.path("content"));
    }

    static String structuredText(JsonNode message, String requiredMarker) {
        String content = text(message);
        if (!content.isBlank()) return content;
        String reasoning = message == null
                ? "" : message.path("reasoning_content").asText("").trim();
        return requiredMarker != null && reasoning.contains(requiredMarker) ? reasoning : "";
    }

    private static String flatten(JsonNode content) {
        if (content == null || content.isMissingNode() || content.isNull()) return "";
        if (content.isTextual()) return content.asText().trim();
        if (!content.isArray()) return "";
        StringBuilder result = new StringBuilder();
        for (JsonNode part : content) {
            String value = part.isTextual() ? part.asText()
                    : part.path("text").asText("");
            if (value.isBlank()) continue;
            if (!result.isEmpty()) result.append('\n');
            result.append(value.trim());
        }
        return result.toString();
    }
}
