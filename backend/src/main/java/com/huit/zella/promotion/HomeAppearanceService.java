package com.huit.zella.promotion;

import com.huit.zella.common.exception.BusinessException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import jakarta.validation.constraints.*;

@Service @RequiredArgsConstructor
public class HomeAppearanceService {
    private final JdbcTemplate jdbc;
    public record Settings(String title,String description,String imageUrl,boolean isDisplay) {}
    public record Request(@NotBlank @Size(max=200) String title,@Size(max=500) String description,
                          @Size(max=500) @Pattern(regexp="https?://[^\\s]+") String imageUrl,@NotNull Boolean isDisplay) {}
    @Transactional(readOnly=true)
    public Settings get() {
        var rows=jdbc.query("select title,description,image_url,is_display from new_product_showcase where id=1",
            (rs,row)->new Settings(rs.getString(1),rs.getString(2),rs.getString(3),rs.getBoolean(4)));
        if(rows.isEmpty()) throw new BusinessException(HttpStatus.NOT_FOUND,"SHOWCASE_NOT_FOUND","Chưa có cấu hình sản phẩm mới");
        return rows.getFirst();
    }
    @Transactional
    public Settings save(Request request) {
        if(Boolean.TRUE.equals(request.isDisplay()) && (request.imageUrl()==null || request.imageUrl().isBlank()))
            throw new BusinessException(HttpStatus.BAD_REQUEST,"IMAGE_REQUIRED","Vui lòng chọn ảnh trước khi bật hiển thị");
        String title=request.title().trim();
        int changed=jdbc.update("update new_product_showcase set title=?,description=?,image_url=?,is_display=? where id=1",
            title,request.description()==null?null:request.description().trim(),request.imageUrl(),Boolean.TRUE.equals(request.isDisplay()));
        if(changed!=1) throw new BusinessException(HttpStatus.NOT_FOUND,"SHOWCASE_NOT_FOUND","Chưa có cấu hình sản phẩm mới");
        return new Settings(title,request.description()==null?null:request.description().trim(),request.imageUrl(),Boolean.TRUE.equals(request.isDisplay()));
    }
}
