package com.atesteme.taskmanager.auth;

import com.atesteme.taskmanager.exception.ConflictException;
import com.atesteme.taskmanager.security.AuthenticatedUserProvider;
import com.atesteme.taskmanager.security.JwtService;
import com.atesteme.taskmanager.user.User;
import com.atesteme.taskmanager.user.UserRepository;
import com.atesteme.taskmanager.user.UserResponse;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;
    private final AuthenticatedUserProvider authenticatedUserProvider;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            AuthenticationManager authenticationManager,
            UserDetailsService userDetailsService,
            JwtService jwtService,
            RefreshTokenService refreshTokenService,
            AuthenticatedUserProvider authenticatedUserProvider
    ) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.authenticationManager = authenticationManager;
        this.userDetailsService = userDetailsService;
        this.jwtService = jwtService;
        this.refreshTokenService = refreshTokenService;
        this.authenticatedUserProvider = authenticatedUserProvider;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase();

        if (userRepository.existsByEmail(normalizedEmail)) {
            throw new ConflictException("Já existe um usuário cadastrado com este e-mail.");
        }

        User user = new User(
                request.name().trim(),
                normalizedEmail,
                passwordEncoder.encode(request.password())
        );
        userRepository.save(user);

        return issueTokens(user);
    }

    public AuthResponse login(LoginRequest request) {
        String normalizedEmail = request.email().trim().toLowerCase();
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(
                normalizedEmail,
                request.password()
        ));

        User user = userRepository.findByEmail(normalizedEmail)
                .orElseThrow(() -> new ConflictException("Usuário não encontrado."));
        return issueTokens(user);
    }

    @Transactional
    public AuthResponse refresh(RefreshTokenRequest request) {
        User user = refreshTokenService.rotate(request.refreshToken());
        return issueTokens(user);
    }

    @Transactional
    public void logout(RefreshTokenRequest request) {
        refreshTokenService.revoke(request.refreshToken());
    }

    public UserResponse me() {
        return UserResponse.from(authenticatedUserProvider.getCurrentUser());
    }

    private AuthResponse issueTokens(User user) {
        UserDetails userDetails = userDetailsService.loadUserByUsername(user.getEmail());
        String accessToken = jwtService.generateToken(userDetails);
        String refreshToken = refreshTokenService.create(user);
        return new AuthResponse(accessToken, refreshToken, UserResponse.from(user));
    }
}
