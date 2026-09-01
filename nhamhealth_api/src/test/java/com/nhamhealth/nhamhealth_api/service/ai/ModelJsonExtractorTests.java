package com.nhamhealth.nhamhealth_api.service.ai;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.Test;

class ModelJsonExtractorTests {
    @Test
    void extractsJsonFromMarkdownAndSurroundingText() {
        assertEquals("{\"meals\":[]}", ModelJsonExtractor.extractObject(
                "Result:\n```json\n{\"meals\":[]}\n```"));
    }

    @Test
    void rejectsTruncatedJson() {
        assertThrows(IllegalArgumentException.class,
                () -> ModelJsonExtractor.extractObject("{\"meals\":[{"));
    }

    @Test
    void repairsOnlyAMissingFinalObjectBrace() {
        assertEquals("{\"name\":\"Egg fried rice\"}",
                ModelJsonExtractor.extractObject("{\"name\":\"Egg fried rice\""));
    }

    @Test
    void rejectsContentCutOffInsideAString() {
        assertThrows(IllegalArgumentException.class,
                () -> ModelJsonExtractor.extractObject("{\"name\":\"Egg fried"));
    }

    @Test
    void rejectsEmptyContent() {
        assertThrows(IllegalArgumentException.class,
                () -> ModelJsonExtractor.extractObject("  "));
    }
}
