package com.huit.zella.post;
import com.huit.zella.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.*;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.context.annotation.*;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.http.MediaType;
import java.util.*;
import static org.mockito.Mockito.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
class PostApiTest {
 @Test void invalidTitleImageAndEmptyContentAreRejectedBeforeSave() throws Exception {
  PostService service=mock(PostService.class);
  MockMvc mvc=MockMvcBuilders.standaloneSetup(new PostManagementController(service)).setControllerAdvice(new GlobalExceptionHandler()).build();
  for(String body:List.of(
   """
   {"categoryId":1,"title":" ","slug":"unused","thumbnail":"https://example.com/a.jpg","content":"Content","status":"DRAFT"}
   """,
   """
   {"categoryId":1,"title":"Title","slug":"title","thumbnail":"javascript:alert(1)","content":"Content","status":"DRAFT"}
   """,
   """
   {"categoryId":1,"title":"Title","slug":"title","thumbnail":"https://example.com/a.jpg","content":" ","status":"DRAFT"}
   """)) {
   mvc.perform(post("/api/v1/admin/posts").contentType(MediaType.APPLICATION_JSON).content(body)).andExpect(status().isBadRequest());
  }
  verifyNoInteractions(service);
 }
 @Configuration @EnableMethodSecurity static class Security {
  @Bean PostService service(){return mock(PostService.class);}
  @Bean PostManagementController controller(PostService service){return new PostManagementController(service);}
 }
 @Test void onlyAdminAndMarketingCanManagePostsAndCategories() {
  try(var context=new AnnotationConfigApplicationContext(Security.class)) {
   var controller=context.getBean(PostManagementController.class);
   for(String role:List.of("USER","SALES","CUSTOMER_SUPPORT","WAREHOUSE")) {
    authenticate(role);
    assertThrows(AccessDeniedException.class,controller::categories);
    assertThrows(AccessDeniedException.class,()->controller.delete(1L));
   }
   for(String role:List.of("ADMIN","MARKETING")) {authenticate(role);assertDoesNotThrow(controller::categories);assertDoesNotThrow(()->controller.delete(1L));}
  } finally {SecurityContextHolder.clearContext();}
 }
 private void authenticate(String role) {SecurityContextHolder.getContext().setAuthentication(UsernamePasswordAuthenticationToken.authenticated("tester","",List.of(new SimpleGrantedAuthority("ROLE_"+role))));}
}
