package com.huit.zella.product;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import java.time.Instant;
import java.util.List;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class FeaturedProductApiTest {
    @Test void publicApiReturnsStatisticsAndEmptyProductsWithoutInventingFallbacks() throws Exception {
        var service=mock(FeaturedProductService.class);var now=Instant.parse("2026-10-16T00:00:00Z");
        when(service.get(8)).thenReturn(new FeaturedProductService.Result(now.minusSeconds(30*86400),now,now,0,3,List.of(),"Featured",null,true));
        var mvc=MockMvcBuilders.standaloneSetup(new FeaturedProductController(service)).build();
        mvc.perform(get("/api/v1/product/featured")).andExpect(status().isOk())
            .andExpect(jsonPath("$.data.totalTransactions").value(0))
            .andExpect(jsonPath("$.data.products").isEmpty())
            .andExpect(jsonPath("$.data.computedAt").exists());
        verify(service).get(8);
    }
}
