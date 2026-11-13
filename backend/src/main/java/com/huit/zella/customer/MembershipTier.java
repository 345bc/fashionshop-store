package com.huit.zella.customer;

import lombok.AccessLevel;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.experimental.FieldDefaults;

import java.math.BigDecimal;

@Getter
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
@AllArgsConstructor
public enum MembershipTier {
    STANDARD(0),
    SILVER(5),
    GOLD(7),
    PLATINUM(10);

    int discountPercent;

    public static MembershipTier fromStoredValue(String value) {
        for (MembershipTier tier : values()) {
            if (tier.name().equals(value)) {
                return tier;
            }
        }
        return STANDARD;
    }
}
