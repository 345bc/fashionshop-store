package com.huit.zella.account;

import com.huit.zella.auth.*;
import com.huit.zella.cart.CartService;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.customer.Customer;
import com.huit.zella.order.*;
import com.huit.zella.orderreturn.*;
import com.huit.zella.review.*;
import com.huit.zella.variantimage.VariantImageRepository;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class CustomerOrderServiceTest {
    private final OrderRepository orders=mock(OrderRepository.class);
    private final OrderService workflow=mock(OrderService.class);
    private final ReturnRepository returns=mock(ReturnRepository.class);
    private final ReturnService returnService=mock(ReturnService.class);
    private final ProductReviewRepository reviews=mock(ProductReviewRepository.class);
    private final UserRepository users=mock(UserRepository.class);
    private final CustomerOrderService service=new CustomerOrderService(orders,workflow,returns,returnService,reviews,users,mock(VariantImageRepository.class),mock(CartService.class));
    private Order order; private OrderItem item;
    @BeforeEach void setup() {
        User owner=new User();owner.setId(1L);owner.setCustomer(new Customer());when(users.findById(1L)).thenReturn(Optional.of(owner));
        order=new Order();order.setId(10L);order.setCustomer(owner);order.setStatus(OrderStatus.DELIVERED);order.setPaymentStatus("PAID");
        item=new OrderItem();item.setId(20L);item.setQuantity(2);order.getItems().add(item);
        when(orders.findByIdForUpdate(10L)).thenReturn(Optional.of(order));when(orders.findById(10L)).thenReturn(Optional.of(order));
    }
    @Test void differentCustomerCannotReadCancelReviewOrReturnOrder() {
        assertThrows(BusinessException.class,()->service.get(10L,2L));
        assertThrows(BusinessException.class,()->service.cancel(10L,2L));
        assertThrows(BusinessException.class,()->service.review(10L,20L,2L,new CustomerOrderService.ReviewRequest(5,"ok")));
        assertThrows(BusinessException.class,()->service.requestReturn(10L,2L,new CreateReturnRequest(10L,"reason",java.util.List.of(new CreateReturnRequest.Item(20L,1)))));
        verifyNoInteractions(workflow,returnService,reviews);
    }
    @Test void reviewRequiresDeliveredPaidUnreturnedOwnedItem() {
        order.setStatus(OrderStatus.SHIPPED);assertThrows(BusinessException.class,()->service.review(10L,20L,1L,new CustomerOrderService.ReviewRequest(5,"ok")));
        order.setStatus(OrderStatus.DELIVERED);when(returns.committedQuantity(20L)).thenReturn(2L);
        assertThrows(BusinessException.class,()->service.review(10L,20L,1L,new CustomerOrderService.ReviewRequest(5,"ok")));
        when(returns.committedQuantity(20L)).thenReturn(0L);
        assertThrows(BusinessException.class,()->service.review(10L,99L,1L,new CustomerOrderService.ReviewRequest(5,"ok")));
        verify(reviews,never()).saveAndFlush(any());
    }
    @Test void reviewEditsSameItemRatherThanCreatingAnotherAndHiddenReviewCannotBeEdited() {
        ProductReview existing=new ProductReview();existing.setId(9L);when(reviews.findByOrderItemId(20L)).thenReturn(Optional.of(existing));
        service.review(10L,20L,1L,new CustomerOrderService.ReviewRequest(4," good "));
        verify(reviews).saveAndFlush(existing);assertEquals(4,existing.getRating());assertEquals("good",existing.getComment());
        existing.setHidden(true);assertThrows(BusinessException.class,()->service.review(10L,20L,1L,new CustomerOrderService.ReviewRequest(5,"ok")));
    }
    @Test void paidConfirmedOrderCannotBeCancelledByCustomer() {
        order.setStatus(OrderStatus.CONFIRMED);assertThrows(BusinessException.class,()->service.cancel(10L,1L));verifyNoInteractions(workflow);
    }
}
