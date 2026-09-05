package com.nhamhealth.nhamhealth_api.service.auth;

import java.time.LocalDateTime;
import java.util.Locale;

import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.nhamhealth.nhamhealth_api.dto.request.ChangePasswordRequest;
import com.nhamhealth.nhamhealth_api.dto.request.LoginRequest;
import com.nhamhealth.nhamhealth_api.dto.request.RegisterRequest;
import com.nhamhealth.nhamhealth_api.dto.response.AuthResponse;
import com.nhamhealth.nhamhealth_api.dto.response.AuthenticatedUserResponse;
import com.nhamhealth.nhamhealth_api.entity.AuthProvider;
import com.nhamhealth.nhamhealth_api.entity.Role;
import com.nhamhealth.nhamhealth_api.entity.User;
import com.nhamhealth.nhamhealth_api.entity.UserAuthProvider;
import com.nhamhealth.nhamhealth_api.entity.UserProfile;
import com.nhamhealth.nhamhealth_api.exception.InvalidSessionException;
import com.nhamhealth.nhamhealth_api.exception.MobileLoginNotAllowedException;
import com.nhamhealth.nhamhealth_api.repository.auth.AuthProviderRepository;
import com.nhamhealth.nhamhealth_api.repository.auth.RoleRepository;
import com.nhamhealth.nhamhealth_api.repository.auth.UserAuthProviderRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserProfileRepository;
import com.nhamhealth.nhamhealth_api.repository.user.UserRepository;
import com.nhamhealth.nhamhealth_api.security.AppUserPrincipal;
import com.nhamhealth.nhamhealth_api.security.JwtTokenService;
import com.nhamhealth.nhamhealth_api.service.sms.PlasgateSmsService;

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
    private final RefreshTokenService refreshTokenService;
    private final PlasgateSmsService smsService;

    public AuthService(
            AuthenticationManager authenticationManager,
            UserRepository userRepository,
            JwtTokenService jwtTokenService,
            PasswordEncoder passwordEncoder,
            RoleRepository roleRepository,
            UserProfileRepository userProfileRepository,
            AuthProviderRepository authProviderRepository,
            UserAuthProviderRepository userAuthProviderRepository,
            GoogleTokenVerifier googleTokenVerifier,
            RefreshTokenService refreshTokenService,
            PlasgateSmsService smsService) {
        this.authenticationManager = authenticationManager;
        this.userRepository = userRepository;
        this.jwtTokenService = jwtTokenService;
        this.passwordEncoder = passwordEncoder;
        this.roleRepository = roleRepository;
        this.userProfileRepository = userProfileRepository;
        this.authProviderRepository = authProviderRepository;
        this.userAuthProviderRepository = userAuthProviderRepository;
        this.googleTokenVerifier = googleTokenVerifier;
        this.refreshTokenService = refreshTokenService;
        this.smsService = smsService;
    }

    @Transactional
    public MobileLoginResult loginMobileUser(LoginRequest request) {
        String rawIdentifier = request.email().trim();
        String identifier = rawIdentifier.contains("@")
                ? rawIdentifier.toLowerCase(Locale.ROOT)
                : smsService.normalizePhoneNumber(rawIdentifier);

        Authentication authentication = authenticationManager.authenticate(
                UsernamePasswordAuthenticationToken.unauthenticated(identifier, request.password()));
        AppUserPrincipal principal = (AppUserPrincipal) authentication.getPrincipal();

        if (!"USER".equals(principal.role())) {
            throw new MobileLoginNotAllowedException();
        }

        User user = userRepository.findById(principal.userId()).orElseThrow();
        if (Boolean.TRUE.equals(user.getLoginOtpRequired())) {
            return new MobileLoginResult(null, user);
        }
        user.setLastLoginAt(LocalDateTime.now());

        return new MobileLoginResult(issueToken(principal), null);
    }

    @Transactional
    public User registerPendingMobileUser(RegisterRequest request) {
        String rawIdentifier = request.email().trim();
        boolean isPhone = !rawIdentifier.contains("@") && rawIdentifier.matches(".*\\d+.*");
        String email = null;
        String phone = null;

        if (isPhone) {
            phone = smsService.normalizePhoneNumber(rawIdentifier);
            if (userRepository.findByPhoneNumber(phone).isPresent()
                    || userProfileRepository.findFirstByPhoneNumber(rawIdentifier).isPresent()
                    || userProfileRepository.findFirstByPhoneNumber(phone).isPresent()) {
                throw new IllegalArgumentException("An account with this phone number already exists");
            }
        } else {
            email = rawIdentifier.toLowerCase(Locale.ROOT);
            if (!isValidEmail(email)) {
                throw new IllegalArgumentException("Please enter a valid email or phone number");
            }
            if (userRepository.findByEmailIgnoreCase(email).isPresent()) {
                throw new IllegalArgumentException("An account with this email already exists");
            }
        }

        User user = new User();
        user.setEmail(email);
        user.setPhoneNumber(phone);
        user.setPasswordHash(passwordEncoder.encode(request.password()));
        user.setRole(requiredUserRole());
        user.setStatus("PENDING");
        user.setIsVerified(false);
        user = userRepository.save(user);

        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName(request.fullName().trim());
        if (phone != null) {
            profile.setPhoneNumber(phone);
            profile.setIsPhoneVerified(false);
        }
        userProfileRepository.save(profile);

        return user;
    }

    @Transactional
    public AuthResponse activateVerifiedUser(User user) {
        user.setStatus("ACTIVE");
        user.setIsVerified(true);
        user.setVerifiedAt(LocalDateTime.now());
        user.setLastLoginAt(LocalDateTime.now());
        user.setLoginOtpRequired(false);
        userRepository.save(user);

        if (user.getPhoneNumber() != null) {
            userProfileRepository.findByUser_UserId(user.getUserId()).ifPresent(profile -> {
                profile.setIsPhoneVerified(true);
                profile.setPhoneVerifiedAt(LocalDateTime.now());
                userProfileRepository.save(profile);
            });
        }

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
        User existingUser = userRepository.findByEmailIgnoreCase(email).orElse(null);
        boolean newlyRegistered = existingUser == null;
        User user = existingUser == null ? createGoogleUser(email) : existingUser;

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

        if (newlyRegistered) {
            createGoogleProfile(user, identity, email);
        }
        return user;
    }

    private User createGoogleUser(String email) {
        User created = new User();
        created.setEmail(email);
        created.setRole(requiredUserRole());
        created.setStatus("ACTIVE");
        created.setIsVerified(true);
        created.setVerifiedAt(LocalDateTime.now());
        return userRepository.save(created);
    }

    private void createGoogleProfile(
            User user,
            GoogleTokenVerifier.GoogleIdentity identity,
            String email) {
        LocalDateTime now = LocalDateTime.now();
        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName(googleNameOrEmail(identity.name(), email));
        if (identity.pictureUrl() != null && !identity.pictureUrl().isBlank()) {
            profile.setProfileImageUrl(identity.pictureUrl().trim());
        }
        profile.setCreatedAt(now);
        profile.setUpdatedAt(now);
        userProfileRepository.save(profile);
    }

    private String googleNameOrEmail(String googleName, String email) {
        if (googleName != null && !googleName.isBlank()) {
            return googleName.trim();
        }
        int atIndex = email.indexOf('@');
        return atIndex > 0 ? email.substring(0, atIndex) : email;
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

    private AuthResponse issueToken(AppUserPrincipal principal) {
        User user = userRepository.findById(principal.userId())
                .orElseThrow(InvalidSessionException::new);
        return issueToken(principal, refreshTokenService.issue(user));
    }

    private AuthResponse issueToken(
            AppUserPrincipal principal,
            RefreshTokenService.IssuedRefreshToken refreshToken) {
        JwtTokenService.IssuedToken token = jwtTokenService.issue(principal);
        AuthenticatedUserResponse responseUser = authenticatedUser(
                principal.userId(), principal.getUsername(), principal.role());
        return new AuthResponse(token.value(), "Bearer", token.expiresIn(),
                refreshToken.value(), refreshToken.expiresIn(), responseUser);
    }

    @Transactional(readOnly = true)
    public AuthenticatedUserResponse authenticatedUser(
            Integer userId,
            String email,
            String role) {
        User user = requireActiveUser(userId);
        UserProfile profile = userProfileRepository.findByUser_UserId(userId).orElse(null);
        String userEmail = user.getEmail() != null && !user.getEmail().isBlank()
                ? user.getEmail()
                : (user.getPhoneNumber() != null ? user.getPhoneNumber() : "");

        return new AuthenticatedUserResponse(
                userId,
                userEmail,
                user.getRoleLabel(),
                profile == null ? null : profile.getFullName(),
                profile == null ? null : profile.getProfileImageUrl(),
                user.hasPin());
    }

    @Transactional
    public void setAppPin(Integer userId, String pin) {
        User user = requireActiveUser(userId);
        user.setPinHash(passwordEncoder.encode(pin));
        user.setPinLength(pin.length());
        userRepository.save(user);
    }

    @Transactional(readOnly = true)
    public boolean verifyAppPin(Integer userId, String pin) {
        User user = requireActiveUser(userId);
        return user.hasPin() && passwordEncoder.matches(pin, user.getPinHash());
    }

    @Transactional
    public void disableAppPin(Integer userId) {
        User user = requireActiveUser(userId);
        user.setPinHash(null);
        user.setPinLength(null);
        userRepository.save(user);
    }

    @Transactional
    public void changePassword(Integer userId, ChangePasswordRequest request) {
        User user = requireActiveUser(userId);

        if (user.getPasswordHash() == null
                || !passwordEncoder.matches(request.currentPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Current password is incorrect");
        }
        if (passwordEncoder.matches(request.newPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("New password must be different from the current password");
        }

        user.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        userRepository.save(user);
        refreshTokenService.revokeAll(user);
    }

    @Transactional(noRollbackFor = com.nhamhealth.nhamhealth_api.exception.PasswordResetException.class)
    public AuthResponse refresh(String refreshToken) {
        RefreshTokenService.RotatedRefreshToken rotated = refreshTokenService.rotate(refreshToken);
        return issueToken(AppUserPrincipal.from(rotated.user()), rotated.token());
    }

    @Transactional
    public void logout(String refreshToken) {
        refreshTokenService.revokeForLogout(refreshToken);
    }

    @Transactional
    public void logoutAll(Integer userId) {
        User user = requireActiveUser(userId);
        user.setLoginOtpRequired(true);
        refreshTokenService.revokeAll(user);
    }

    @Transactional
    public AuthResponse completeLoginOtp(User user) {
        User managed = requireActiveUser(user.getUserId());
        managed.setLoginOtpRequired(false);
        managed.setLastLoginAt(LocalDateTime.now());
        return issueToken(AppUserPrincipal.from(managed));
    }

    public record MobileLoginResult(AuthResponse response, User otpUser) {
        public boolean otpRequired() { return otpUser != null; }
    }

    private User requireActiveUser(Integer userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(InvalidSessionException::new);
        if (!"ACTIVE".equalsIgnoreCase(user.getStatus())
                || !Boolean.TRUE.equals(user.getIsVerified())) {
            throw new InvalidSessionException();
        }
        return user;
    }

    private boolean isValidEmail(String email) {
        int at = email.indexOf('@');
        return at > 0
                && at == email.lastIndexOf('@')
                && at < email.length() - 3
                && email.indexOf('.', at + 2) > at + 1
                && email.chars().noneMatch(Character::isWhitespace);
    }
}
