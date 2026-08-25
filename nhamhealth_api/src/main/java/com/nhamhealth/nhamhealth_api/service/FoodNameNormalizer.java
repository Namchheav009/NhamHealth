package com.nhamhealth.nhamhealth_api.service;

import java.text.Normalizer;
import java.util.Arrays;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import org.springframework.stereotype.Component;

@Component
public class FoodNameNormalizer {
    private static final Map<String, String> KNOWN_ALIASES = Map.ofEntries(
            Map.entry("white rice", "cooked rice"),
            Map.entry("steamed white rice", "cooked rice"),
            Map.entry("jasmine rice cooked", "cooked jasmine rice"),
            Map.entry("pork rice", "bai sach chrouk"),
            Map.entry("rice with pork", "bai sach chrouk"),
            Map.entry("khmer noodle", "num banh chok"),
            Map.entry("khmer noodles", "num banh chok"),
            Map.entry("rice noodle soup", "kuy teav"),
            Map.entry("beef lok lak", "lok lak"),
            Map.entry("rice porridge", "borbor"),
            Map.entry("fried noodle", "mee cha"),
            Map.entry("fried noodles", "mee cha"));

    public String normalize(String value) {
        if (value == null || value.isBlank()) return "";
        String normalized = Normalizer.normalize(value, Normalizer.Form.NFKD)
                .replaceAll("\\p{M}+", "")
                .toLowerCase(Locale.ROOT)
                .replaceAll("[^a-z0-9\\p{L}]+", " ")
                .trim()
                .replaceAll("\\s+", " ");
        String known = KNOWN_ALIASES.get(normalized);
        if (known != null) return known;
        List<String> tokens = Arrays.stream(normalized.split(" "))
                .filter(token -> !token.isBlank())
                .map(this::singularize)
                .toList();
        String result = String.join(" ", tokens);
        return KNOWN_ALIASES.getOrDefault(result, result);
    }

    private String singularize(String token) {
        if (!token.matches("[a-z]+") || token.length() <= 3) return token;
        if (token.endsWith("ies") && token.length() > 4) {
            return token.substring(0, token.length() - 3) + "y";
        }
        if (token.endsWith("ches") || token.endsWith("shes") || token.endsWith("xes")) {
            return token.substring(0, token.length() - 2);
        }
        if (token.endsWith("s") && !token.endsWith("ss")
                && !token.endsWith("us") && !token.endsWith("is")) {
            return token.substring(0, token.length() - 1);
        }
        return token;
    }
}
