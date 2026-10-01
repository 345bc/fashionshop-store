package com.huit.zella.supplier;

import com.huit.zella.common.exception.BusinessException;
import com.huit.zella.product.ProductRepository;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Locale;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SupplierService {
    SupplierRepository supplierRepository;
    ProductRepository productRepository;

    @Transactional(readOnly = true)
    public List<SupplierResponse> list(String query) {
        String q = query == null ? "" : query.trim().toLowerCase(Locale.ROOT);
        return supplierRepository.findAll(Sort.by("name", "id")).stream()
                .filter(s -> q.isEmpty() || contains(s.getName(), q) || contains(s.getCode(), q)
                        || contains(s.getContactEmail(), q) || contains(s.getPhone(), q))
                .map(SupplierResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public SupplierResponse get(Long id) {
        return SupplierResponse.from(requireSupplier(id));
    }

    @Transactional
    public SupplierResponse create(CreateSupplierRequest request) {
        Supplier supplier = new Supplier();
        apply(supplier, request);
        return SupplierResponse.from(supplierRepository.save(supplier));
    }

    @Transactional
    public SupplierResponse update(Long id, CreateSupplierRequest request) {
        Supplier supplier = requireSupplier(id);
        apply(supplier, request);
        return SupplierResponse.from(supplierRepository.save(supplier));
    }

    @Transactional
    public void delete(Long id) {
        Supplier supplier = requireSupplier(id);
        if (productRepository.existsBySupplierId(id) || supplierRepository.countGoodsReceipts(id) > 0) {
            throw new BusinessException(HttpStatus.CONFLICT, "SUPPLIER_IN_USE", "Supplier has products or goods receipts");
        }
        supplierRepository.delete(supplier);
    }

    private Supplier requireSupplier(Long id) {
        return supplierRepository.findById(id).orElseThrow(() ->
                new BusinessException(HttpStatus.NOT_FOUND, "SUPPLIER_NOT_FOUND", "Supplier not found"));
    }

    private void apply(Supplier supplier, CreateSupplierRequest request) {
        String code = clean(request.code());
        if (code != null && (supplier.getId() == null
                ? supplierRepository.existsByCodeIgnoreCase(code)
                : supplierRepository.existsByCodeIgnoreCaseAndIdNot(code, supplier.getId()))) {
            throw new BusinessException(HttpStatus.CONFLICT, "SUPPLIER_CODE_EXISTS", "Supplier code already exists");
        }
        supplier.setName(request.name().trim());
        supplier.setCode(code);
        supplier.setContactEmail(clean(request.contactEmail()));
        supplier.setPhone(clean(request.phone()));
        supplier.setAddress(clean(request.address()));
        supplier.setContactPerson(clean(request.contactPerson()));
        supplier.setIsActive(request.isActive() == null || request.isActive());
    }

    private String clean(String value) {
        return value == null || value.trim().isEmpty() ? null : value.trim();
    }

    private boolean contains(String value, String query) {
        return value != null && value.toLowerCase(Locale.ROOT).contains(query);
    }

}
