package com.huit.zella.orderreturn;

import com.huit.zella.order.Order;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;

public record ReturnOrderSummaryResponse(Long orderId, String orderCode, String recipientName,
        String recipientPhone, BigDecimal totalAmount, OffsetDateTime latestRequestAt,
        int totalRequests, int pendingRequests, List<String> statuses) {
    static ReturnOrderSummaryResponse from(Order order, List<ReturnRequest> requests) {
        var latest = requests.stream().map(ReturnRequest::getCreatedAt).max(java.util.Comparator.naturalOrder()).orElseThrow();
        return new ReturnOrderSummaryResponse(order.getId(), order.getCode(), order.getRecipientName(),
                order.getRecipientPhone(), order.getTotalAmount(), latest.atOffset(ZoneOffset.UTC), requests.size(),
                (int) requests.stream().filter(r -> r.getStatus() == ReturnStatus.PENDING).count(),
                requests.stream().map(r -> r.getStatus().name()).distinct().toList());
    }
}
