package com.nhamhealth.nhamhealth_api.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import org.junit.jupiter.api.Test;

import com.fasterxml.jackson.databind.ObjectMapper;

class NvidiaChatResponseParserTests {
    private final ObjectMapper mapper = new ObjectMapper();

    @Test
    void readsPlainTextContent() throws Exception {
        assertEquals("Healthy choice", NvidiaChatResponseParser.text(
                mapper.readTree("{\"content\":\" Healthy choice \"}")));
    }

    @Test
    void joinsTextPartsReturnedByMultimodalModels() throws Exception {
        assertEquals("first\nsecond", NvidiaChatResponseParser.text(mapper.readTree("""
                {"content":[{"type":"text","text":"first"},"second"]}
                """)));
    }

    @Test
    void usesReasoningContentOnlyWhenItContainsTheRequiredStructuredResult()
            throws Exception {
        var message = mapper.readTree("""
                {"content":"","reasoning_content":"analysis {\\"meals\\":[]}"}
                """);

        assertEquals("analysis {\"meals\":[]}",
                NvidiaChatResponseParser.structuredText(message, "\"meals\""));
        assertEquals("", NvidiaChatResponseParser.structuredText(message, "\"components\""));
    }
}
