package com.huit.zella.color;

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
@RequestMapping("/api/v1/color")
@RequiredArgsConstructor
@FieldDefaults(level = AccessLevel.PRIVATE, makeFinal = true)
public class ColorController {
    ColorService colorService;

    @GetMapping
    public ApiResponse<List<ColorResponse>> list() {
        return ApiResponse.success(colorService.list());
    }

    @GetMapping("/{id}")
    public ApiResponse<ColorResponse> get(@PathVariable Integer id) {
        return ApiResponse.success(colorService.get(id));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PostMapping
    public ResponseEntity<ApiResponse<ColorResponse>> create(@Valid @RequestBody CreateColorRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(colorService.create(request)));
    }

    @PreAuthorize("hasAnyRole('ADMIN', 'EMPLOYEE')")
    @PutMapping("/{id}")
    public ApiResponse<ColorResponse> update(@PathVariable Integer id, @Valid @RequestBody CreateColorRequest request) {
        return ApiResponse.success(colorService.update(id, request));
    }

    @PreAuthorize("hasRole('ADMIN')")
    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@PathVariable Integer id) {
        colorService.delete(id);
        return ApiResponse.success(null);
    }
}
