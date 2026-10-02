package com.huit.zella.order;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
import com.huit.zella.order.CreateOrderRequest.Item;

public record CreateCheckoutOrderRequest(
    @NotBlank @Size(max = 150) String recipientName,
    @NotBlank @Pattern(regexp = "0[0-9]{9}") String recipientPhone,
    @NotBlank @Size(max = 350) String address,
    @Size(max = 500) String note,
    @NotBlank @Pattern(regexp = "STANDARD|EXPRESS") String shippingMethod,
    @NotEmpty @Size(max = 200) List<@Valid Item> items
) {}
