package com.huit.zella.size;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import lombok.AccessLevel;
import lombok.RequiredArgsConstructor;
import lombok.experimental.FieldDefaults;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/size")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class SizeController {
    SizeService sizeService;

    @GetMapping
    public ApiResponse<List<SizeResponse>> list() {
        return ApiResponse.success(sizeService.list());
    }

    @GetMapping("/{id}")
    public ApiResponse<SizeResponse> get(@PathVariable Integer id) {
        return ApiResponse.success(sizeService.get(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping
    public ResponseEntity<ApiResponse<SizeResponse>> create(@Valid @RequestBody CreateSizeRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(sizeService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<SizeResponse> update(@PathVariable Integer id, @Valid @RequestBody CreateSizeRequest request) {
        return ApiResponse.success(sizeService.update(id, request));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Integer id) {
        sizeService.delete(id);
        return ApiResponse.success(null);
    }
}
