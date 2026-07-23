package com.nhamhealth.nhamhealth_api.health;

import java.time.Instant;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/health")
public class ApiHealthController {

	@GetMapping
	public ResponseEntity<ApiHealthResponse> health() {
		return ResponseEntity.ok(new ApiHealthResponse(
				"UP",
				"nhamhealth-api",
				Instant.now()));
	}
}
