package com.huit.zella.supplier;

import com.huit.zella.sizeguide.SizeGuideRepository;
import com.huit.zella.sizeguide.SizeGuideResponse;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SupplierService {
    SupplierRepository supplierRepository  ;

    public List<SupplierRespone> get() {
        return supplierRepository.findAll()
                .stream()
                .map(SupplierRespone::from)
                .toList();
    }


}
