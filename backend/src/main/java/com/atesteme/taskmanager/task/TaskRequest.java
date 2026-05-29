package com.atesteme.taskmanager.task;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record TaskRequest(
        @NotBlank(message = "Título da tarefa é obrigatório.")
        @Size(max = 160, message = "Título deve ter no máximo 160 caracteres.")
        String title,

        @Size(max = 700, message = "Descrição deve ter no máximo 700 caracteres.")
        String description,

        @NotNull(message = "Prioridade é obrigatória.")
        TaskPriority priority,

        @NotNull(message = "Status é obrigatório.")
        TaskStatus status
) {
}

