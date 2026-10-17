package com.huit.zella.post;

import com.huit.zella.common.api.ApiResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.web.bind.annotation.*;
import java.time.Duration;
import java.util.UUID;

@RestController @RequestMapping("/api/v1/posts/{slug}")
public class PostViewController {
    private static final String COOKIE="zella_reader";
    private final PostViewService service;
    private final boolean secure;
    public PostViewController(PostViewService service,@Value("${app.auth.jwt.cookie-secure:false}") boolean secure){this.service=service;this.secure=secure;}
    public record ViewRequest(@NotBlank @Pattern(regexp="[0-9a-fA-F-]{36}") String token) {}
    @PostMapping("/view-session")
    public ResponseEntity<ApiResponse<PostViewService.Started>> start(@PathVariable String slug,@CookieValue(name=COOKIE,required=false) String cookie) {
        String browser=validBrowser(cookie)?cookie:UUID.randomUUID().toString();
        var started=service.start(slug,browser);
        var response=ResponseEntity.ok().cacheControl(CacheControl.noStore());
        if(!browser.equals(cookie)) response.header(HttpHeaders.SET_COOKIE,ResponseCookie.from(COOKIE,browser)
                .httpOnly(true).secure(secure).sameSite("Lax").path("/").maxAge(Duration.ofDays(365)).build().toString());
        return response.body(ApiResponse.success(started));
    }
    @PostMapping("/views")
    public ApiResponse<PostViewService.Counted> count(@PathVariable String slug,@CookieValue(name=COOKIE,required=false) String cookie,@Valid @RequestBody ViewRequest request) {
        if(!validBrowser(cookie)) throw new com.huit.zella.common.exception.BusinessException(HttpStatus.BAD_REQUEST,"POST_VIEW_COOKIE_REQUIRED","Trình duyệt chưa có phiên đọc hợp lệ");
        return ApiResponse.success(service.count(slug,cookie,request.token()));
    }
    private boolean validBrowser(String value){try{return value!=null && UUID.fromString(value).toString().equals(value);}catch(IllegalArgumentException e){return false;}}
}
