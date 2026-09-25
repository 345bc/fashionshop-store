package com.huit.zella.sizeguide;

import com.huit.zella.category.CategoryRepository;
import com.huit.zella.category.CategoryResponse;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SizeGuideService {
    SizeGuideRepository sizeGuideRepository ;

    public List<SizeGuideResponse> get() {
        return sizeGuideRepository.findAll()
                .stream()
                .map(SizeGuideResponse::create)
                .toList();
    }


}
