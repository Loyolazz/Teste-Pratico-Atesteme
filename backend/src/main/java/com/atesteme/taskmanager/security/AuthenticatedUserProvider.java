package com.atesteme.taskmanager.security;

import com.atesteme.taskmanager.exception.ResourceNotFoundException;
import com.atesteme.taskmanager.user.User;
import com.atesteme.taskmanager.user.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;

@Component
public class AuthenticatedUserProvider {

    private final UserRepository userRepository;

    public AuthenticatedUserProvider(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public User getCurrentUser() {
        String email = SecurityContextHolder.getContext().getAuthentication().getName();
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new ResourceNotFoundException("Usuário autenticado não encontrado."));
    }
}

