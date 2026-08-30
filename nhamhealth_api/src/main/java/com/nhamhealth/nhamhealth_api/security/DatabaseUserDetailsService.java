package com.nhamhealth.nhamhealth_api.security;

import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;

@Service
public class DatabaseUserDetailsService implements UserDetailsService {

    private final UserRepository userRepository;

    public DatabaseUserDetailsService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        User user = userRepository.findByEmailIgnoreCase(email.trim())
                .filter(candidate -> candidate.getPasswordHash() != null
                        && !candidate.getPasswordHash().isBlank()
                        && Boolean.TRUE.equals(candidate.getIsVerified())
                        && "ACTIVE".equalsIgnoreCase(candidate.getStatus()))
                .orElseThrow(() -> new UsernameNotFoundException("Invalid email or password"));

        return AppUserPrincipal.from(user);
    }
}
