package com.huit.zella.orderreturn;

import com.huit.zella.inventory.WarehouseFixture;
import com.huit.zella.order.*;
import com.huit.zella.common.exception.BusinessException;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = "app.order.expiration.enabled=false") @Transactional
class ReturnManagementWorkflowTest extends WarehouseFixture {
    @Autowired OrderService orders;
    @Autowired ReturnService returns;
    @Autowired WebApplicationContext context;

    private OrderResponse delivered() {
        var order = orders.create(new CreateOrderRequest(actor.getId(), "Khách quản lý", "0900000000", "Test", null,
                BigDecimal.ZERO, "ONLINE", List.of(new CreateOrderRequest.Item(variant.getId(), 2))), actor.getId());
        orders.recordOnlinePayment(order.id(), order.totalAmount(), UUID.randomUUID().toString());
        orders.ship(order.id(), actor.getId()); orders.deliver(order.id(), actor.getId());
        return order;
    }
    private ReturnResponse request(OrderResponse order) {
        return returns.create(new CreateReturnRequest(order.id(), "Trả một sản phẩm",
                List.of(new CreateReturnRequest.Item(order.items().getFirst().id(), 1))), actor.getId());
    }

    @Test void invoiceAppearsOnceAndOrdersWithoutRequestsAreExcluded() {
        var order = delivered(); delivered();
        var first = request(order); request(order);
        var result = returns.management(order.code(), "ALL", PageRequest.of(0, 10));
        assertEquals(1, result.getTotalElements());
        assertEquals(order.id(), result.getContent().getFirst().orderId());
        assertEquals(2, result.getContent().getFirst().totalRequests());
        assertEquals(2, result.getContent().getFirst().pendingRequests());
        returns.approve(first.id(), actor.getId());
        var approved = returns.management(order.code(), "APPROVED", PageRequest.of(0, 10));
        assertEquals(1, approved.getTotalElements());
        assertEquals(1, approved.getContent().getFirst().pendingRequests());
        assertTrue(approved.getContent().getFirst().statuses().containsAll(List.of("PENDING", "APPROVED")));
        assertTrue(returns.management(order.code(), "COMPLETED", PageRequest.of(0, 10)).isEmpty());
    }

    @Test void pagesCountUniqueInvoicesAndFilterRecipientOrCode() {
        var first = delivered(); var second = delivered(); request(first); request(second);
        var pageable = PageRequest.of(0, 1, Sort.by(Sort.Direction.DESC, "id"));
        var result = returns.management("Khách quản lý", "PENDING", pageable);
        assertEquals(2, result.getTotalElements()); assertEquals(2, result.getTotalPages());
        assertEquals(second.id(), result.getContent().getFirst().orderId());
        var next = returns.management("0900000000", "PENDING", pageable.next());
        assertEquals(first.id(), next.getContent().getFirst().orderId());
        assertEquals(1, returns.management(first.code(), "ALL", PageRequest.of(0, 10)).getTotalElements());
        assertThrows(BusinessException.class, () -> returns.management("", "INVALID", pageable));
    }

    @Test void managementEndpointRequiresAdminOrEmployee() throws Exception {
        var mvc = MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
        mvc.perform(get("/api/v1/order-return/management")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/v1/order-return/management").with(user("customer").roles("USER"))).andExpect(status().isForbidden());
        mvc.perform(get("/api/v1/order-return/management").with(user("admin").roles("ADMIN"))).andExpect(status().isOk());
        mvc.perform(get("/api/v1/order-return/management").with(user("employee").roles("CUSTOMER_SUPPORT"))).andExpect(status().isOk());
    }
}
