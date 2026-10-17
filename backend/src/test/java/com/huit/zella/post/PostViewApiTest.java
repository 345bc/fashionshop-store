package com.huit.zella.post;
import com.huit.zella.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import jakarta.servlet.http.Cookie;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
class PostViewApiTest {
    @Test void anonymousSessionIssuesHttpOnlyCookieAndMissingCookieCannotCount() throws Exception {
        var service=mock(PostViewService.class);
        when(service.start(eq("bai-viet"),anyString())).thenReturn(new PostViewService.Started("token",10));
        var mvc=MockMvcBuilders.standaloneSetup(new PostViewController(service,true)).setControllerAdvice(new GlobalExceptionHandler()).build();
        mvc.perform(post("/api/v1/posts/bai-viet/view-session")).andExpect(status().isOk())
            .andExpect(cookie().httpOnly("zella_reader",true)).andExpect(cookie().secure("zella_reader",true))
            .andExpect(jsonPath("$.data.minimumSeconds").value(10));
        mvc.perform(post("/api/v1/posts/bai-viet/views").contentType("application/json").content("{\"token\":\"12345678-1234-1234-1234-123456789012\"}"))
            .andExpect(status().isBadRequest());
        verify(service,never()).count(anyString(),anyString(),anyString());
    }
    @Test void existingBrowserCookieIsPreservedAndCountIsBoundToCookie() throws Exception {
        var service=mock(PostViewService.class);String browser="12345678-1234-1234-1234-123456789012";
        when(service.start("bai-viet",browser)).thenReturn(new PostViewService.Started("token",10));
        when(service.count("bai-viet",browser,browser)).thenReturn(new PostViewService.Counted(false,8));
        var mvc=MockMvcBuilders.standaloneSetup(new PostViewController(service,false)).setControllerAdvice(new GlobalExceptionHandler()).build();
        mvc.perform(post("/api/v1/posts/bai-viet/view-session").cookie(new Cookie("zella_reader",browser)))
            .andExpect(status().isOk()).andExpect(header().doesNotExist("Set-Cookie"));
        mvc.perform(post("/api/v1/posts/bai-viet/views").cookie(new Cookie("zella_reader",browser))
            .contentType("application/json").content("{\"token\":\""+browser+"\"}"))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.counted").value(false));
    }
}
