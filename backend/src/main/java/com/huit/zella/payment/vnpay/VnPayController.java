package com.huit.zella.payment.vnpay;

import com.huit.zella.common.api.ApiResponse;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.util.MultiValueMap;
import org.springframework.web.bind.annotation.*;

@RestController
@RequiredArgsConstructor
@Slf4j
public class VnPayController {
    private final VnPayService service;

    @PostMapping("/api/v1/checkout/orders/{code}/payment")
    public ApiResponse<VnPayService.PaymentResponse> payment(@PathVariable String code,
            @RequestHeader("X-Checkout-Token") String token, HttpServletRequest request) {
        return ApiResponse.success(service.payment(code, token, request.getRemoteAddr()));
    }

    @PostMapping("/api/v1/checkout/orders/{code}/payment/verify")
    public ApiResponse<Map<String, String>> verifyReturn(@PathVariable String code,
            @RequestHeader("X-Checkout-Token") String token,
            @RequestParam MultiValueMap<String, String> parameters) {
        return ApiResponse.success(service.verifyReturn(code, token, parameters));
    }

    @GetMapping("/api/v1/payment/vnpay/ipn")
    public Map<String, String> ipn(@RequestParam MultiValueMap<String, String> parameters) {
        try {
            Map<String, String> response = service.ipn(parameters);
            String reference = parameters.getFirst("vnp_TxnRef");
            String safeReference = reference != null && reference.matches("[0-9]{1,19}") ? reference : "unknown";
            // Record acknowledgement codes so missing IPN delivery and rejected callbacks can be distinguished.
            // Never log the complete callback query or signing secret.
            log.info("VNPay IPN orderId={} acknowledgement={}", safeReference, response.get("RspCode"));
            return response;
        }
        catch (RuntimeException ex) {
            // Do not log the signed query or secret. A non-success acknowledgement makes VNPay retry.
            log.error("VNPay IPN could not be processed ({})", ex.getClass().getSimpleName());
            return VnPayService.result("99", "Unable to process payment");
        }
    }
}
