package com.atesteme.taskmanager.common;

public record FieldErrorResponse(
        String field,
        String message
) {
}

