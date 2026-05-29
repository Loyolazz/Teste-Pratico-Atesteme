package com.atesteme.taskmanager.task;

import java.time.Instant;

public record TaskResponse(
        Long id,
        String title,
        String description,
        TaskPriority priority,
        TaskStatus status,
        Instant createdAt,
        Long projectId
) {
}

