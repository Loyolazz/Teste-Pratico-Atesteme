package com.atesteme.taskmanager.project;

import java.time.Instant;
import java.util.List;

public record ProjectResponse(
        Long id,
        String name,
        String description,
        List<String> workers,
        Instant createdAt,
        int taskCount
) {
}
