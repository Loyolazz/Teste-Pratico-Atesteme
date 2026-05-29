package com.atesteme.taskmanager.auth;

import com.atesteme.taskmanager.user.UserResponse;

public record AuthResponse(
        String accessToken,
        String refreshToken,
        UserResponse user
) {
}
