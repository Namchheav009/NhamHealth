package com.nhamhealth.nhamhealth_api.service;

import java.time.LocalDateTime;
import java.util.Locale;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.response.AuthResponse;
import com.nhamhealth.nhamhealth_api.dto.response.AuthenticatedUserResponse;
import com.nhamhealth.nhamhealth_api.dto.request.LoginRequest;
import com.nhamhealth.nhamhealth_api.dto.request.RegisterRequest;
import com.nhamhealth.nhamhealth_api.dto.request.ChangePasswordRequest;
import com.nhamhealth.nhamhealth_api.entity.AuthProvider;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserAuthProvider;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.exception.MobileLoginNotAllowedException;
import com.nhamhealth.nhamhealth_api.repository.AuthProviderRepository;
import com.nhamhealth.nhamhealth_api.repository.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.UserAuthProviderRepository;
import com.nhamhealth.nhamhealth_api.repository.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.UserRepository;
import com.nhamhealth.nhamhealth_api.security.AppUserPrincipal;
import com.nhamhealth.nhamhealth_api.security.JwtTokenService;
import org.springframework.security.crypto.password.PasswordEncoder;

@Service
public class AuthService {

    private final AuthenticationManager authenticationManager;
    private final UserRepository userRepository;
    private final JwtTokenService jwtTokenService;
    private final PasswordEncoder passwordEncoder;
    private final RoleRepository roleRepository;
    private final UserProfileRepository userProfileRepository;
    private final AuthProviderRepository authProviderRepository;
    private final UserAuthProviderRepository userAuthProviderRepository;
    private final GoogleTokenVerifier googleTokenVerifier;

    public AuthService(
            AuthenticationManager authenticationManager,
            UserRepository userRepository,
            JwtTokenService jwtTokenService,
            PasswordEncoder passwordEncoder,
            RoleRepository roleRepository,
            UserProfileRepository userProfileRepository,
            AuthProviderRepository authProviderRepository,
            UserAuthProviderRepository userAuthProviderRepository,
            GoogleTokenVerifier googleTokenVerifier) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtTokenService = jwtTokenService;
        this.passwordEncoder = passwordEncoder;
        this.roleRepository = roleRepository;
        this.userProfileRepository = userProfileRepository;
        this.authProviderRepository = authProviderRepository;
        this.userAuthProviderRepository = userAuthProviderRepository;
        this.googleTokenVerifier = googleTokenVerifier;
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

        return issueToken(principal);
    }

    @Transactional
    public User registerPendingMobileUser(RegisterRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        if (userRepository.findByEmailIgnoreCase(email).isPresent()) {
            throw new IllegalArgumentException("An account with this email already exists");
        }

        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(requiredUserRole());
        user.setStatus("PENDING");
        user.setIsVerified(false);
        user = userRepository.save(user);

        createProfile(user, request.fullName().trim(), null);
        return user;
    }

    @Transactional
    public AuthResponse activateVerifiedUser(User user) {
        user.setStatus("ACTIVE");
        user.setIsVerified(true);
        user.setVerifiedAt(LocalDateTime.now());
        user.setLastLoginAt(LocalDateTime.now());
        userRepository.save(user);
        return issueToken(AppUserPrincipal.from(user));
    }

    @Transactional
    public AuthResponse loginWithGoogle(String idToken) {
        GoogleTokenVerifier.GoogleIdentity identity = googleTokenVerifier.verify(idToken);
        String email = identity.email().trim().toLowerCase(Locale.ROOT);

        User user = userAuthProviderRepository
                .findByAuthProvider_ProviderNameIgnoreCaseAndProviderUserKey(
                        "GOOGLE", identity.subject())
                .map(UserAuthProvider::getUser)
                .orElseGet(() -> linkGoogleIdentity(identity, email));

        if (!"USER".equalsIgnoreCase(user.getRole().getRoleName())) {
            throw new MobileLoginNotAllowedException();
        }

        syncGoogleProfile(user, identity);
        user.setLastLoginAt(LocalDateTime.now());
        user.setStatus("ACTIVE");
        user.setIsVerified(true);
        user.setVerifiedAt(user.getVerifiedAt() == null
                ? LocalDateTime.now()
                : user.getVerifiedAt());
        userRepository.save(user);
        return issueToken(AppUserPrincipal.from(user));
    }

    private User linkGoogleIdentity(
            GoogleTokenVerifier.GoogleIdentity identity,
            String email) {
        User user = userRepository.findByEmailIgnoreCase(email).orElseGet(() -> {
            User created = new User();
            created.setEmail(email);
            created.setRole(requiredUserRole());
            created.setStatus("ACTIVE");
            created.setIsVerified(true);
            created.setVerifiedAt(LocalDateTime.now());
            User saved = userRepository.save(created);
            createProfile(
                    saved,
                    identity.name() == null || identity.name().isBlank()
                            ? email.substring(0, email.indexOf('@'))
                            : identity.name(),
                    identity.pictureUrl());
            return saved;
        });

        AuthProvider google = authProviderRepository
                .findByProviderNameIgnoreCase("GOOGLE")
                .orElseGet(() -> {
                    AuthProvider provider = new AuthProvider();
                    provider.setProviderName("GOOGLE");
                    provider.setIsActive(true);
                    return authProviderRepository.save(provider);
                });

        UserAuthProvider link = new UserAuthProvider();
        link.setUser(user);
        link.setAuthProvider(google);
        link.setProviderUserKey(identity.subject());
        link.setProviderEmail(email);
        link.setLinkedAt(LocalDateTime.now());
        userAuthProviderRepository.save(link);
        return user;
    }

    private Role requiredUserRole() {
        return roleRepository.findByRoleNameIgnoreCase("USER")
                .orElseGet(() -> {
                    Role role = new Role();
                    role.setRoleName("USER");
                    role.setDescription("Standard User");
                    return roleRepository.save(role);
                });
    }

    private void createProfile(User user, String fullName, String pictureUrl) {
        if (userProfileRepository.findByUser_UserId(user.getUserId()).isPresent()) {
            return;
        }
        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName(fullName);
        profile.setProfileImageUrl(pictureUrl);
        profile.setCreatedAt(now);
        profile.setUpdatedAt(now);
        userProfileRepository.save(profile);
    }

    private void syncGoogleProfile(
            User user,
            GoogleTokenVerifier.GoogleIdentity identity) {
        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = userProfileRepository.findByUser_UserId(user.getUserId())
                .orElseGet(() -> {
                    UserProfile created = new UserProfile();
                    created.setUser(user);
                    created.setFullName(defaultGoogleName(identity));
                    created.setCreatedAt(now);
                    return created;
                });

        if (identity.name() != null && !identity.name().isBlank()) {
            profile.setFullName(identity.name().trim());
        }
        if (identity.pictureUrl() != null && !identity.pictureUrl().isBlank()) {
            profile.setProfileImageUrl(identity.pictureUrl().trim());
        }
        profile.setUpdatedAt(now);
        userProfileRepository.save(profile);
    }

    private String defaultGoogleName(GoogleTokenVerifier.GoogleIdentity identity) {
        if (identity.name() != null && !identity.name().isBlank()) {
            return identity.name().trim();
        }
        String email = identity.email().trim();
        int separator = email.indexOf('@');
        return separator > 0 ? email.substring(0, separator) : email;
    }

    private AuthResponse issueToken(AppUserPrincipal principal) {
        JwtTokenService.IssuedToken token = jwtTokenService.issue(principal);
        AuthenticatedUserResponse responseUser = authenticatedUser(
                principal.userId(), principal.getUsername(), principal.role());
        return new AuthResponse(token.value(), "Bearer", token.expiresIn(), responseUser);
    }

    @Transactional(readOnly = true)
    public AuthenticatedUserResponse authenticatedUser(
            Integer userId,
            String email,
            String role) {
        String currentEmail = userRepository.findById(userId)
                .map(User::getEmail)
                .orElse(email);
        UserProfile profile = userProfileRepository.findByUser_UserId(userId).orElse(null);
        return new AuthenticatedUserResponse(
                userId,
                currentEmail,
                role,
                profile == null ? null : profile.getFullName(),
                profile == null ? null : profile.getProfileImageUrl());
    }

    @Transactional
    public void changePassword(Integer userId, ChangePasswordRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User account was not found"));

        if (user.getPasswordHash() == null
                || !passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }
        if (passwordEncoder.matches(request.newPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("New password must be different from the current password");
        }

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
    }
}
