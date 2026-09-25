package com.huit.zella.customer;

import com.huit.zella.auth.User;
import com.huit.zella.auth.UserRepository;
import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.Product;
import com.huit.zella.product.ProductResponse;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
class CustomerService {
    CustomerRepository customerRepository;
    UserRepository userRepository;

    @Transactional(readOnly = true)
    public CustomerResponse get(Long id) {
        return CustomerResponse.from(requireFeature(id));
    }

//    public CustomerResponse updateCustomer(Long id, CustomerResponse customerDto) {
//        customer existingCustomer = customerRepository.findById(id)
//                .orElseThrow(() -> new RuntimeException("Customer not found with id: " + id));
//
//        existingCustomer.setFullName(customerDto.getFullName());
//        existingCustomer.setEmail(customerDto.getEmail());
//        existingCustomer.setPhone(customerDto.getPhone());
//        existingCustomer.setAddress(customerDto.getAddress());
//
//        customer updatedCustomer = customerRepository.save(existingCustomer);
//        return mapToDto(updatedCustomer);
//    }

    private Customer requireFeature(Long id) {
        return customerRepository.findByUserId(id).orElseThrow(() -> new BusinessException(
                HttpStatus.NOT_FOUND, "ID_NOT_FOUND", "ID not found"
        ));
    }
}
