package com.nhamhealth.nhamhealth_api.controller.api;

import java.io.IOException;

import org.springframework.http.MediaType;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;
import com.nhamhealth.nhamhealth_api.dto.request.AiFoodFeedbackRequest;
import com.nhamhealth.nhamhealth_api.service.ai.AiFoodAnalysisService;
import jakarta.validation.Valid;
import java.util.Map;

import static org.springframework.http.HttpStatus.BAD_REQUEST;

@RestController
@RequestMapping("/api/v1/ai/food")
public class AiFoodAnalysisController {
    private static final int NVIDIA_INLINE_IMAGE_LIMIT_BYTES = 180 * 1024;
    private final AiFoodAnalysisService service;

    public AiFoodAnalysisController(AiFoodAnalysisService service) {
        this.service = service;
    }

    @PostMapping(value = "/analyze", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public AiFoodAnalysisResponse analyze(
            @AuthenticationPrincipal Jwt jwt,
            @RequestParam("image") MultipartFile image) throws IOException {
        if (image.isEmpty()) {
            throw new ResponseStatusException(BAD_REQUEST, "A food image is required.");
        }
        byte[] imageBytes = image.getBytes();
        String detectedContentType = detectContentType(imageBytes);
        if (detectedContentType == null) {
            throw new ResponseStatusException(BAD_REQUEST, "Upload a valid JPG, PNG, or WebP food image.");
        }
        if (imageBytes.length > NVIDIA_INLINE_IMAGE_LIMIT_BYTES) {
            throw new ResponseStatusException(
                    org.springframework.http.HttpStatus.PAYLOAD_TOO_LARGE,
                    "The AI image must be 180 KB or smaller. Crop or compress it and try again.");
        }
        Number userId = jwt.getClaim("userId");
        return service.analyzeAndSave(
                userId.intValue(), image.getOriginalFilename(), imageBytes, detectedContentType);
    }

    @PostMapping("/{analysisId}/feedback")
    public Map<String, Object> feedback(
            @AuthenticationPrincipal Jwt jwt,
            @PathVariable Integer analysisId,
            @Valid @RequestBody AiFoodFeedbackRequest request) {
        Number userId = jwt.getClaim("userId");
        service.saveFeedback(userId.intValue(), analysisId, request);
        return Map.of("saved", true, "analysisId", analysisId);
    }

    private static String detectContentType(byte[] bytes) {
        if (bytes.length >= 3
                && Byte.toUnsignedInt(bytes[0]) == 0xFF
                && Byte.toUnsignedInt(bytes[1]) == 0xD8
                && Byte.toUnsignedInt(bytes[2]) == 0xFF) {
            return MediaType.IMAGE_JPEG_VALUE;
        }
        if (bytes.length >= 8
                && Byte.toUnsignedInt(bytes[0]) == 0x89
                && bytes[1] == 0x50
                && bytes[2] == 0x4E
                && bytes[3] == 0x47
                && bytes[4] == 0x0D
                && bytes[5] == 0x0A
                && bytes[6] == 0x1A
                && bytes[7] == 0x0A) {
            return MediaType.IMAGE_PNG_VALUE;
        }
        if (bytes.length >= 12
                && bytes[0] == 'R' && bytes[1] == 'I' && bytes[2] == 'F' && bytes[3] == 'F'
                && bytes[8] == 'W' && bytes[9] == 'E' && bytes[10] == 'B' && bytes[11] == 'P') {
            return "image/webp";
        }
        return null;
    }
}
