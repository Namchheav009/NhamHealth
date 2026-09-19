package com.nhamhealth.nhamhealth_api.security;

import java.time.LocalDateTime;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.nhamhealth.nhamhealth_api.entity.ModerationActionType;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.community.ModerationActionRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

@Service
public class DatabaseUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;
    private final PlasgateSmsService smsService;
    private final ModerationActionRepository moderationActions;

    public DatabaseUserDetailsService(
            UserRepository userRepository,
            PlasgateSmsService smsService,
            ModerationActionRepository moderationActions) {
        this.userRepository = userRepository;
        this.smsService = smsService;
        this.moderationActions = moderationActions;
    }

    @Override
    public UserDetails loadUserByUsername(String identifier) throws UsernameNotFoundException {
        if (identifier == null || identifier.isBlank()) {
            throw new UsernameNotFoundException("Invalid email or password");
        }

        String raw = identifier.trim();
        boolean isEmail = raw.contains("@");

        User user;
        if (isEmail) {
            user = userRepository.findByEmailIgnoreCase(raw)
                    .filter(this::hasPassword)
                    .orElseThrow(() -> new UsernameNotFoundException("Invalid email or password"));
        } else {
            String normalized = smsService.normalizePhoneNumber(raw);
            user = userRepository.findByPhoneNumber(normalized)
                    .or(() -> userRepository.findByPhoneNumber(raw))
                    .filter(this::hasPassword)
                    .orElseThrow(() -> new UsernameNotFoundException("Invalid email or password"));
        }

        if ("SUSPENDED".equalsIgnoreCase(user.getStatus())) {
            boolean hasActive = !moderationActions.findActiveRestrictions(
                    user.getUserId(), ModerationActionType.SUSPENDED, LocalDateTime.now()).isEmpty();
            if (!hasActive) {
                user.setStatus("ACTIVE");
                userRepository.save(user);
            }
        }

        return AppUserPrincipal.from(user);
    }

    private boolean hasPassword(User candidate) {
        return candidate.getPasswordHash() != null && !candidate.getPasswordHash().isBlank();
    }
}
