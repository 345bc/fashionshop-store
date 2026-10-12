package com.huit.zella.voucher;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;
import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;

/** Voucher dates use UTC, including values inserted by SQL's SYSUTCDATETIME(). */
@Converter
public class UtcDateTimeConverter implements AttributeConverter<LocalDateTime, Instant> {
    @Override public Instant convertToDatabaseColumn(LocalDateTime value) {
        return value == null ? null : value.toInstant(ZoneOffset.UTC);
    }
    @Override public LocalDateTime convertToEntityAttribute(Instant value) {
        return value == null ? null : LocalDateTime.ofInstant(value, ZoneOffset.UTC);
    }
}
