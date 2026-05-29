package com.atesteme.taskmanager.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "Nome é obrigatório.")
        @Size(max = 120, message = "Nome deve ter no máximo 120 caracteres.")
        String name,

        @NotBlank(message = "E-mail é obrigatório.")
        @Email(message = "E-mail inválido.")
        @Size(max = 160, message = "E-mail deve ter no máximo 160 caracteres.")
        String email,

        @NotBlank(message = "Senha é obrigatória.")
        @Size(min = 6, max = 80, message = "Senha deve ter entre 6 e 80 caracteres.")
        String password
) {
}

