package com.nhamhealth.nhamhealth_api.service.ai;

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
        if (start < 0) {
            throw new IllegalArgumentException("The model returned an incomplete JSON object.");
        }

        int objectDepth = 0;
        int arrayDepth = 0;
        boolean inString = false;
        boolean escaped = false;
        for (int index = start; index < cleaned.length(); index++) {
            char current = cleaned.charAt(index);
            if (inString) {
                if (escaped) {
                    escaped = false;
                } else if (current == '\\') {
                    escaped = true;
                } else if (current == '"') {
                    inString = false;
                }
                continue;
            }
            if (current == '"') {
                inString = true;
            } else if (current == '{') {
                objectDepth++;
            } else if (current == '}') {
                objectDepth--;
                if (objectDepth == 0 && arrayDepth == 0) {
                    return cleaned.substring(start, index + 1);
                }
            } else if (current == '[') {
                arrayDepth++;
            } else if (current == ']') {
                arrayDepth--;
            }
            if (objectDepth < 0 || arrayDepth < 0) break;
        }

        // Some providers occasionally stop immediately before the final
        // top-level brace. Repair only that unambiguous case; never invent a
        // value, finish a string, or close nested structures.
        String partial = cleaned.substring(start).trim();
        if (!inString && objectDepth == 1 && arrayDepth == 0
                && hasCompleteFinalValue(partial)) {
            return partial + "}";
        }
        throw new IllegalArgumentException("The model returned an incomplete JSON object.");
    }

    private static boolean hasCompleteFinalValue(String partial) {
        if (partial.isEmpty()) return false;
        char last = partial.charAt(partial.length() - 1);
        return last == '"' || last == ']' || last == '}'
                || Character.isDigit(last) || last == 'e' || last == 'l';
    }
}
