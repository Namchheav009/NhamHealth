package com.nhamhealth.nhamhealth_api.service.ai;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.ai.AiUserHealthProfile;
import com.nhamhealth.nhamhealth_api.repository.wellness.WellnessProfileRepository;

@Service
public class AiUserHealthProfileService {
    private final WellnessProfileRepository wellnessProfileRepository;

    public AiUserHealthProfileService(WellnessProfileRepository wellnessProfileRepository) {
        this.wellnessProfileRepository = wellnessProfileRepository;
    }

    @Transactional(readOnly = true)
    public AiUserHealthProfile load(Integer userId) {
        return wellnessProfileRepository.findByUser_UserId(userId)
                .map(profile -> AiUserHealthProfile.from(userId, profile))
                .orElseGet(() -> AiUserHealthProfile.empty(userId));
    }
}
