package com.nhamhealth.nhamhealth_api.dto.ai;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

@JsonIgnoreProperties(ignoreUnknown = true)
public record FoodCandidate(String name, double confidence) {
}
