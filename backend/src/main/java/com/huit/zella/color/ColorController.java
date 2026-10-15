package com.huit.zella.color;

import org.springframework.data.domain.Sort;
import org.springframework.data.domain.PageRequest;

import com.huit.zella.common.api.PageResponse;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/color")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ColorController {
    ColorService colorService;

    @GetMapping
    public ApiResponse<PageResponse<ColorResponse>> list(
            @RequestParam(required = false) String q,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        int safeSize = Math.max(1, Math.min(size, 100));
        return ApiResponse.success(PageResponse.from(colorService.list(
                q,
                PageRequest.of(Math.max(page, 0), safeSize, Sort.by(Sort.Direction.DESC, "id"))
        )));
    }

    @PreAuthorize("hasAnyRole('ADMIN')")
    @PostMapping
    public ResponseEntity<ApiResponse<ColorResponse>> create(@Valid @RequestBody CreateColorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(colorService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN')")
    @PutMapping("/{id}")
    public ApiResponse<ColorResponse> update(@PathVariable Integer id, @Valid @RequestBody CreateColorRequest request) {
        return ApiResponse.success(colorService.update(id, request));
    }

}
