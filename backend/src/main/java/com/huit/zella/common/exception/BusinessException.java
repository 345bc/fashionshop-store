package com.huit.zella.common.exception;

import org.springframework.http.HttpStatus;

/**
 * Throw this exception from a Service when a business rule is violated.
 */
public class BusinessException extends RuntimeException {
    private final HttpStatus status;
    private final String code;

    public BusinessException(HttpStatus status, String code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public String getCode() {
        return code;
    }
}
