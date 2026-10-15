package com.huit.zella.dashboard;

import jakarta.validation.constraints.*;
import org.springframework.format.annotation.DateTimeFormat;
import java.time.*;
import java.time.temporal.ChronoUnit;

public record DashboardQuery(
        @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate start,
        @NotNull @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate end,
        Section section,
        @Size(max = 200) String q,
        @Size(max = 100) String category,
        @Pattern(regexp = "PENDING|CONFIRMED|SHIPPED|DELIVERED|CANCELLED|RETURNED") String status,
        @Min(0) @Max(1000000) Integer page,
        @Min(1) @Max(100) Integer size) {
    public enum Section { overview, revenue, orders, returns, products, inventory, customers, purchases, promotions }
    public DashboardQuery {
        section = section == null ? Section.overview : section;
        q = q == null ? "" : q.strip();
        page = page == null ? 0 : page;
        size = size == null ? 10 : size;
    }
    @AssertTrue(message = "Khoảng ngày tối đa 366 ngày, ngày bắt đầu không sau ngày kết thúc và không vượt hôm nay")
    public boolean isValidRange() {
        return start == null || end == null || (!end.isBefore(start)
                && ChronoUnit.DAYS.between(start, end) <= 365
                && !end.isAfter(LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh"))));
    }
    public LocalDate previousStart() { return start.minusDays(ChronoUnit.DAYS.between(start, end) + 1); }
}
