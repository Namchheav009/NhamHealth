package com.nhamhealth.nhamhealth_api.dto.request;

import java.util.List;

public record BulkMealFavoritesRequest(List<Integer> mealIds) {
}
