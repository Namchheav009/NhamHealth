package com.nhamhealth.nhamhealth_api.dto.response;

import java.time.Instant;

public record ApiHealthResponse(
		String status,
		String service,
		Instant timestamp) {
}
