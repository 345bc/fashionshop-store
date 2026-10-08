package com.huit.zella.product;

import com.huit.zella.common.api.ApiResponse;
import com.huit.zella.common.api.PageResponse;
import com.huit.zella.user.UpdateUserRequest;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/product")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ProductController {
    ProductService productService;

    @GetMapping("/cards")
    public ApiResponse<PageResponse<ProductCardResponse>> listCards(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size,
            @RequestParam(defaultValue = "featured") String sort,
            @RequestParam(required = false) List<Integer> colorIds,
            @RequestParam(required = false) List<Integer> sizeIds
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        Sort cardSort = switch (sort) {
            case "low" -> Sort.by(
                    Sort.Order.asc("basePrice"),
                    Sort.Order.desc("id")
            );
            case "high" -> Sort.by(
                    Sort.Order.desc("basePrice"),
                    Sort.Order.desc("id")
            );
            default -> Sort.by(Sort.Direction.DESC, "id");
        };

        return ApiResponse.success(PageResponse.from(
                productService.listCards(
                        q,
                        categoryId,
                        colorIds,
                        sizeIds,
                        PageRequest.of(
                                Math.max(page, 0),
                                safeSize,
                                cardSort
                        )
                )
        ));
    }

    @GetMapping
    public ApiResponse<PageResponse<ProductResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(required = false) Long categoryId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "15") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(productService.list(
                q, categoryId,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping
    public ResponseEntity<ApiResponse<ProductResponse>> create(
            @Valid @RequestBody CreateProductRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success(productService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @GetMapping("/{id}")
    public ApiResponse<ProductResponse> get(@PathVariable Long id) {
        return ApiResponse.success(productService.get(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<ProductResponse> update(
            @PathVariable Long id,
            @Valid @RequestBody CreateProductRequest request
    ) {
        return ApiResponse.success(productService.update(id, request));
    }
}
