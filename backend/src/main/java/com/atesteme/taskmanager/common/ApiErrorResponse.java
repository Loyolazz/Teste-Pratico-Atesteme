package com.atesteme.taskmanager.common;

import java.time.Instant;
import java.util.List;
import org.slf4j.MDC;

public record ApiErrorResponse(
        Instant timestamp,
        int status,
        String error,
        String message,
        String path,
        String requestId,
        List<FieldErrorResponse> fieldErrors
) {

    public static ApiErrorResponse of(int status, String error, String message, String path) {
        return new ApiErrorResponse(Instant.now(), status, error, message, path, MDC.get("requestId"), List.of());
    }

    public static ApiErrorResponse withFields(
            int status,
            String error,
            String message,
            String path,
            List<FieldErrorResponse> fieldErrors
    ) {
        return new ApiErrorResponse(Instant.now(), status, error, message, path, MDC.get("requestId"), fieldErrors);
    }
}
