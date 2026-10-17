package com.huit.zella.promotion;

import com.huit.zella.product.ProductService;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Clock;

@Service @RequiredArgsConstructor
public class AutomaticNewProductShowcaseService {
    private final JdbcTemplate jdbc;
    private final ProductService products;
    private final Clock orderClock;
    @Transactional(readOnly=true)
    public NewProductSpotlightService.Spotlight get() {
        var assets=jdbc.query("select title,description,image_url from new_product_showcase where id=1 and is_display=1",
                (rs,row)->new String[]{rs.getString(1),rs.getString(2),rs.getString(3)});
        if(assets.isEmpty() || assets.getFirst()[2]==null || assets.getFirst()[2].isBlank()) return null;
        var items=products.listNewArrivalsAt(orderClock.instant(),PageRequest.of(0,12,
                Sort.by(Sort.Order.desc("createdAt"),Sort.Order.desc("id")))).getContent();
        if(items.isEmpty()) return null;
        var asset=assets.getFirst();
        return new NewProductSpotlightService.Spotlight(asset[0],asset[0],asset[1],asset[2],null,null,items,-1L,"NEW_PRODUCTS");
    }
}
