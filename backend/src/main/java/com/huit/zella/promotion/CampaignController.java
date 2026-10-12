package com.huit.zella.promotion;
import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController @RequestMapping("/api/v1/campaigns") @RequiredArgsConstructor
@PreAuthorize("hasAnyRole('ADMIN','EMPLOYEE')")
public class CampaignController {
    private final CampaignManagementService service;
    @GetMapping("/products") public ApiResponse<List<CampaignResponse.ProductOption>> products(){return ApiResponse.success(service.catalog());}
    @GetMapping("/{kind}") public ApiResponse<List<CampaignResponse>> list(@PathVariable String kind){return ApiResponse.success(service.list(kind));}
    @GetMapping("/{kind}/{id}") public ApiResponse<CampaignResponse> detail(@PathVariable String kind,@PathVariable Long id){return ApiResponse.success(service.detail(kind,id));}
    @PostMapping("/{kind}") public ApiResponse<CampaignResponse> create(@PathVariable String kind,@Valid @RequestBody CampaignRequest request){return ApiResponse.success(service.save(kind,null,request));}
    @PutMapping("/{kind}/{id}") public ApiResponse<CampaignResponse> update(@PathVariable String kind,@PathVariable Long id,@Valid @RequestBody CampaignRequest request){return ApiResponse.success(service.save(kind,id,request));}
    public record StateRequest(boolean enabled){}
    @PatchMapping("/{kind}/{id}/state") public ApiResponse<CampaignResponse> state(@PathVariable String kind,@PathVariable Long id,@Valid @RequestBody StateRequest request){return ApiResponse.success(service.state(kind,id,request.enabled()));}
}
