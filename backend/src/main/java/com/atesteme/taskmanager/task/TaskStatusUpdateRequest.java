package com.atesteme.taskmanager.task;

import jakarta.validation.constraints.NotNull;

public record TaskStatusUpdateRequest(
        @NotNull(message = "Status é obrigatório.")
        TaskStatus status
) {
}

