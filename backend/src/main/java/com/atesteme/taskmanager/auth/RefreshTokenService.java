package com.atesteme.taskmanager.auth;

import com.atesteme.taskmanager.user.User;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class RefreshTokenService {

    private final RefreshTokenRepository refreshTokenRepository;
    private final SecureRandom secureRandom = new SecureRandom();
    private final long expirationMs;

    public RefreshTokenService(
            RefreshTokenRepository refreshTokenRepository,
            @Value("${security.jwt.refresh-expiration-ms}") long expirationMs
    ) {
        this.refreshTokenRepository = refreshTokenRepository;
        this.expirationMs = expirationMs;
    }

    @Transactional
    public String create(User user) {
        String rawToken = generateToken();
        RefreshToken refreshToken = new RefreshToken(
                hash(rawToken),
                user,
                Instant.now().plusMillis(expirationMs)
        );
        refreshTokenRepository.save(refreshToken);
        return rawToken;
    }

    @Transactional
    public User rotate(String rawToken) {
        RefreshToken refreshToken = findActive(rawToken);
        refreshToken.revoke();
        return refreshToken.getUser();
    }

    @Transactional
    public void revoke(String rawToken) {
        refreshTokenRepository.findByTokenHash(hash(rawToken))
                .ifPresent(RefreshToken::revoke);
    }

    private RefreshToken findActive(String rawToken) {
        RefreshToken refreshToken = refreshTokenRepository.findByTokenHash(hash(rawToken))
                .orElseThrow(() -> new BadCredentialsException("Refresh token inválido."));

        if (!refreshToken.isActive()) {
            throw new BadCredentialsException("Refresh token inválido.");
        }

        return refreshToken;
    }

    private String generateToken() {
        byte[] bytes = new byte[48];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private String hash(String token) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(token.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(hash);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 indisponível.", exception);
        }
    }
}

