package com.huit.zella.customer;

import com.huit.zella.auth.CurrentUser;
import com.huit.zella.auth.UserService;
import com.huit.zella.common.exception.BusinessException;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
class CustomerService {
    CustomerRepository customerRepository;
    UserService userService;
    PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<CustomerResponse> list(String query) {
        String q = query == null ? "" : query.trim().toLowerCase(java.util.Locale.ROOT);
        return customerRepository.findAll(Sort.by(Sort.Direction.DESC, "id")).stream()
                .filter(c -> q.isEmpty() || contains(c.getFullName(), q) || contains(c.getPhone(), q)
                        || contains(c.getUser().getEmail(), q))
                .map(CustomerResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public CustomerResponse get(Long id) {
        return CustomerResponse.from(requireFeature(id));
    }

    @Transactional(readOnly = true)
    public CustomerResponse getById(Long id) {
        return CustomerResponse.from(customerRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "CUSTOMER_NOT_FOUND", "Customer not found")));
    }



    @Transactional
    public CustomerResponse update(Long id, UpdateCustomerRequest request) {
        Customer customer = customerRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "CUSTOMER_NOT_FOUND", "Customer not found"));
        customer.setFullName(request.fullName().trim());
        customer.setPhone(clean(request.phone()));
        customer.setAddress(clean(request.address()));
        if (request.isActive() != null) {
            customer.getUser().setActive(request.isActive());
        }
        return CustomerResponse.from(customerRepository.save(customer));
    }

    private String clean(String value) {
        return value == null || value.trim().isEmpty() ? null : value.trim();
    }

    private boolean contains(String value, String query) {
        return value != null && value.toLowerCase(java.util.Locale.ROOT).contains(query);
    }

    private Customer requireFeature(Long id) {
        return customerRepository.findByUserId(id).orElseThrow(() -> new BusinessException(
                HttpStatus.NOT_FOUND, "ID_NOT_FOUND", "ID not found"
        ));
    }
}
