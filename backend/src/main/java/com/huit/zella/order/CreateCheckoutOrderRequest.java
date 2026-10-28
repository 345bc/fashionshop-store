package com.huit.zella.order;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
import com.huit.zella.order.CreateOrderRequest.Item;

public record CreateCheckoutOrderRequest(
    @NotBlank @Size(max = 150) String recipientName,
    @NotBlank @Pattern(regexp = "0[0-9]{9}", message = "Số điện thoại phải có 10 chữ số và bắt đầu bằng 0") String recipientPhone,
    @NotBlank @Size(max = 350) String address,
    @Size(max = 500) String note,
    @NotBlank @Pattern(regexp = "STANDARD|EXPRESS") String shippingMethod,
    @NotEmpty @Size(max = 200) List<@NotNull @Valid Item> items,
    @Pattern(regexp = "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-4[a-fA-F0-9]{3}-[89aAbB][a-fA-F0-9]{3}-[a-fA-F0-9]{12}") String checkoutKey,
    @Size(max=50) String voucherCode,
    @Email @Size(max = 254) String recipientEmail
) {
    public CreateCheckoutOrderRequest(String recipientName, String recipientPhone, String address, String note,
            String shippingMethod, List<Item> items, String checkoutKey, String voucherCode) {
        this(recipientName, recipientPhone, address, note, shippingMethod, items, checkoutKey, voucherCode, null);
    }
    public CreateCheckoutOrderRequest(String recipientName, String recipientPhone, String address, String note,
            String shippingMethod, List<Item> items) {
        this(recipientName, recipientPhone, address, note, shippingMethod, items, null, null);
    }
    public CreateCheckoutOrderRequest(String recipientName,String recipientPhone,String address,String note,String shippingMethod,List<Item> items,String checkoutKey) {
        this(recipientName,recipientPhone,address,note,shippingMethod,items,checkoutKey,null);
    }
}
