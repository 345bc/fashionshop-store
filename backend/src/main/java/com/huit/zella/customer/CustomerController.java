package com.huit.zella.customer;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.product.ProductResponse;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/customers")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CustomerController {

    CustomerService customerService;

    @GetMapping("/user/{id}")
    public ApiResponse<CustomerResponse> getCustomerByUserId(@PathVariable Long id) {
        return ApiResponse.success(customerService.get(id));
    }

//    @PutMapping("/{id}")
//    public ResponseEntity<CustomerResponse> updateCustomer(@PathVariable Long id, @RequestBody CustomerResponse customerDto) {
//        return ResponseEntity.ok(customerService.updateCustomer(id, customerDto));
//    }
}
