package com.nhamhealth.nhamhealth_api.service;

import java.time.LocalDateTime;
import java.util.Locale;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.AuthResponse;
import com.nhamhealth.nhamhealth_api.dto.AuthenticatedUserResponse;
import com.nhamhealth.nhamhealth_api.dto.LoginRequest;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.exception.MobileLoginNotAllowedException;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.security.AppUserPrincipal;
import com.nhamhealth.nhamhealth_api.security.JwtTokenService;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final JwtTokenService jwtTokenService;

    public AuthService(
            AuthenticationManager authenticationManager,
            UserRepository userRepository,
            JwtTokenService jwtTokenService) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtTokenService = jwtTokenService;
    }

    @Transactional
    public AuthResponse loginMobileUser(LoginRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        Authentication authentication = authenticationManager.authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated(email, request.password()));
        AppUserPrincipal principal = (AppUserPrincipal) authentication.getPrincipal();

        if (!"USER".equals(principal.role())) {
            throw new MobileLoginNotAllowedException();
        }

        User user = userRepository.findById(principal.userId()).orElseThrow();
        user.setLastLoginAt(LocalDateTime.now());

        JwtTokenService.IssuedToken token = jwtTokenService.issue(principal);
        AuthenticatedUserResponse responseUser = new AuthenticatedUserResponse(
                principal.userId(), principal.getUsername(), principal.role());
        return new AuthResponse(token.value(), "Bearer", token.expiresIn(), responseUser);
    }
}
