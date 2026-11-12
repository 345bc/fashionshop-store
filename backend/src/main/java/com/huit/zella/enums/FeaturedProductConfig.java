package com.huit.zella.enums;

import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.experimental.Accessors;

@Getter
@Accessors(fluent = true)
@RequiredArgsConstructor
public enum FeaturedProductConfig {
    DEFAULT("Sản phẩm nổi bật", null, 30, 60, 40, true);

    private final String title;
    private final String description;
    private final int windowDays;
    private final int purchaseWeight;
    private final int reviewWeight;
    private final boolean display;
}
