package com.huit.zella.common.api;

import java.time.Instant;

/**
 * Success response contract shared by all project features.
 */
public record ApiResponse<T>(
        T data,
        String message,
        Instant timestamp
) {
    public static <T> ApiResponse<T> success(T data) {
        return new ApiResponse<>(data, null, Instant.now());
    }

    public static <T> ApiResponse<T> success(T data, String message) {
        return new ApiResponse<>(data, message, Instant.now());
    }
}
