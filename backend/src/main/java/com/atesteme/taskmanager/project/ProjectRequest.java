package com.atesteme.taskmanager.project;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.List;

public record ProjectRequest(
        @NotBlank(message = "Nome do projeto é obrigatório.")
        @Size(max = 120, message = "Nome deve ter no máximo 120 caracteres.")
        String name,

        @Size(max = 500, message = "Descrição deve ter no máximo 500 caracteres.")
        String description,

        @Size(max = 24, message = "Informe no máximo 24 pessoas no projeto.")
        List<@Size(max = 80, message = "Nome da pessoa deve ter no máximo 80 caracteres.") String> workers
) {
}
