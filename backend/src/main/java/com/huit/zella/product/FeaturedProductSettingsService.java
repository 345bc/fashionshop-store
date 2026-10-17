package com.huit.zella.product;
import com.huit.zella.common.exception.BusinessException;
import jakarta.validation.constraints.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service @RequiredArgsConstructor
public class FeaturedProductSettingsService {
    private final JdbcTemplate jdbc;
    public record Settings(String title,String description,int windowDays,int purchaseWeight,int reviewWeight,boolean isDisplay) {}
    public record Request(@NotBlank @Size(max=200) String title,@Size(max=500) String description,
        @NotNull @Min(1) @Max(365) Integer windowDays,@NotNull @Min(0) @Max(100) Integer purchaseWeight,
        @NotNull @Min(0) @Max(100) Integer reviewWeight,@NotNull Boolean isDisplay) {}
    @Transactional(readOnly=true)
    public Settings get() {
        var rows=jdbc.query("select title,description,window_days,purchase_weight,review_weight,is_display from featured_product_settings where id=1",
            (rs,row)->new Settings(rs.getString(1),rs.getString(2),rs.getInt(3),rs.getInt(4),rs.getInt(5),rs.getBoolean(6)));
        if(rows.isEmpty()) throw new BusinessException(HttpStatus.NOT_FOUND,"FEATURED_SETTINGS_NOT_FOUND","Chưa có cấu hình sản phẩm nổi bật");
        return rows.getFirst();
    }
    @Transactional
    public Settings save(Request r) {
        if(r.purchaseWeight()+r.reviewWeight()!=100) throw new BusinessException(HttpStatus.BAD_REQUEST,"INVALID_FEATURED_WEIGHTS","Tổng tỷ trọng mua hàng và đánh giá phải bằng 100%");
        int updated=jdbc.update("update featured_product_settings set title=?,description=?,window_days=?,purchase_weight=?,review_weight=?,is_display=? where id=1",
            r.title().trim(),r.description()==null?null:r.description().trim(),r.windowDays(),r.purchaseWeight(),r.reviewWeight(),r.isDisplay());
        if(updated!=1) throw new BusinessException(HttpStatus.NOT_FOUND,"FEATURED_SETTINGS_NOT_FOUND","Chưa có cấu hình sản phẩm nổi bật");
        return new Settings(r.title().trim(),r.description()==null?null:r.description().trim(),r.windowDays(),r.purchaseWeight(),r.reviewWeight(),r.isDisplay());
    }
}
