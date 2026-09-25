package com.huit.zella.category;

import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class CategoryService {
    CategoryRepository categoryRepository;

    public List<CategoryResponse> get() {
        return categoryRepository.findAllByParentIsNotNull()
                .stream()
                .map(CategoryResponse::create)
                .toList();
    }


}
