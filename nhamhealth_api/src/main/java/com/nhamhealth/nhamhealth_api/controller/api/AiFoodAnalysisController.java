package com.nhamhealth.nhamhealth_api.controller.api;

import java.io.IOException;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.nhamhealth.nhamhealth_api.dto.response.AiFoodAnalysisResponse;
import com.nhamhealth.nhamhealth_api.service.NvidiaFoodVisionService;

@RestController
@RequestMapping("/api/v1/ai/food")
public class AiFoodAnalysisController {
    private final NvidiaFoodVisionService service;

    public AiFoodAnalysisController(NvidiaFoodVisionService service) {
        this.service = service;
    }

    @PostMapping(value = "/analyze", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public AiFoodAnalysisResponse analyze(@RequestParam("image") MultipartFile image) throws IOException {
        if (image.isEmpty()) {
            throw new IllegalArgumentException("A food image is required.");
        }
        return service.analyze(image.getBytes(), image.getContentType());
    }
}
