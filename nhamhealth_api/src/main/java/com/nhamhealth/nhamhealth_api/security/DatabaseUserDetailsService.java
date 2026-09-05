package com.nhamhealth.nhamhealth_api.security;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

@Service
public class DatabaseUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;
    private final PlasgateSmsService smsService;

    public DatabaseUserDetailsService(
            UserRepository userRepository,
            PlasgateSmsService smsService) {
        this.userRepository = userRepository;
        this.smsService = smsService;
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
                    .filter(this::isEligible)
                    .orElseThrow(() -> new UsernameNotFoundException("Invalid email or password"));
        } else {
            String normalized = smsService.normalizePhoneNumber(raw);
            user = userRepository.findByPhoneNumber(normalized)
                    .or(() -> userRepository.findByPhoneNumber(raw))
                    .filter(this::isEligible)
                    .orElseThrow(() -> new UsernameNotFoundException("Invalid email or password"));
        }

        return AppUserPrincipal.from(user);
    }

    private boolean isEligible(User candidate) {
        return candidate.getPasswordHash() != null
                && !candidate.getPasswordHash().isBlank()
                && Boolean.TRUE.equals(candidate.getIsVerified())
                && "ACTIVE".equalsIgnoreCase(candidate.getStatus());
    }
}
