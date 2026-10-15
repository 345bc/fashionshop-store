package com.huit.zella.staff;
import com.huit.zella.auth.*;
import jakarta.servlet.http.Cookie;
import java.util.UUID;
import org.junit.jupiter.api.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.*;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.WebApplicationContext;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.csrf;
import static org.springframework.security.test.web.servlet.setup.SecurityMockMvcConfigurers.springSecurity;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
@SpringBootTest(properties="app.order.expiration.enabled=false") @Transactional
class StaffWorkflowTest {
 @Autowired WebApplicationContext context;
 @Autowired UserRepository users;
 @Autowired RoleRepository roles;
 @Autowired StaffRepository staff;
 @Autowired PasswordEncoder passwords;
 MockMvc mvc;User admin,target;Cookie access;
 @BeforeEach void setup() throws Exception {
  mvc=MockMvcBuilders.webAppContextSetup(context).apply(springSecurity()).build();
  admin=account("ADMIN");target=account("SALES");access=login(admin).getResponse().getCookie("ACCESS_TOKEN");
 }
 User account(String role){var u=new User();String key=UUID.randomUUID().toString().substring(0,12);u.setUserName("staff-"+key);u.setEmail(key+"@example.test");u.setPasswordHash(passwords.encode("Password123!"));u.getRoles().add(roles.findByRoleCode(role).orElseThrow());return users.saveAndFlush(u);}
 MvcResult login(User u)throws Exception{return mvc.perform(post("/api/v1/auth/login").contentType("application/json").content("{\"email\":\""+u.getEmail()+"\",\"password\":\"Password123!\"}")).andExpect(status().isOk()).andReturn();}
 String body(Long id,String state,String role){return "{\"userId\":"+id+",\"fullName\":\"Nhân sự kiểm thử\",\"position\":\"Chuyên viên\",\"phone\":\"0901234567\",\"hiredDate\":\"2026-01-01\",\"status\":\""+state+"\",\"roles\":[\""+role+"\"],\"accountActive\":true}";}
 String accountBody(User u,boolean active,String role) {
  return "{\"username\":\""+u.getUserName()+"\",\"email\":\""+u.getEmail()+"\",\"roles\":[\""+role+"\"],\"isActive\":"+active+"}";
 }
 Staff link(User u) {
  Staff s=new Staff();s.setUser(u);s.setFullName("Nhân sự kiểm thử");s.setPosition("Chuyên viên");s.setHiredDate(java.time.LocalDate.of(2026,1,1));staff.saveAndFlush(s);
  return s;
 }
 @Test void searchByEmailAndDuplicateAccountsAreRejected()throws Exception {
  var s=link(target);assertEquals(target.getId(),s.getUser().getId());assertNotNull(s.getId());
  mvc.perform(post("/api/v1/staff").cookie(access).with(csrf()).contentType("application/json").content("{\"fullName\":\"Nhân sự\",\"phone\":\"0901234567\",\"hiredDate\":\"2026-01-01\",\"username\":\""+target.getUserName()+"\",\"email\":\""+target.getEmail()+"\",\"password\":\"Password123!\"}")).andExpect(status().isConflict());
  mvc.perform(get("/api/v1/staff").cookie(access).param("q",target.getEmail()).param("active","true")).andExpect(status().isOk()).andExpect(jsonPath("$.data.content[0].userId").value(target.getId()));
 }
 @Test void terminationRevokesAccessAndRefreshEvenAfterReactivation()throws Exception {
  var s=link(target);var logged=login(target);
  mvc.perform(put("/api/v1/user/"+target.getId()).cookie(access).with(csrf()).contentType("application/json").content(accountBody(target,false,"SALES"))).andExpect(status().isOk()).andExpect(jsonPath("$.data.isActive").value(false));
  mvc.perform(get("/api/v1/auth/me").cookie(logged.getResponse().getCookie("ACCESS_TOKEN"))).andExpect(status().isUnauthorized());
  mvc.perform(post("/api/v1/auth/refresh").with(csrf()).cookie(logged.getResponse().getCookie("REFRESH_TOKEN"))).andExpect(status().isUnauthorized());
  mvc.perform(put("/api/v1/user/"+target.getId()).cookie(access).with(csrf()).contentType("application/json").content(accountBody(target,true,"SALES"))).andExpect(status().isOk());
  mvc.perform(get("/api/v1/auth/me").cookie(logged.getResponse().getCookie("ACCESS_TOKEN"))).andExpect(status().isUnauthorized());
 }
 @Test void changingRoleRevokesOldSessionAndPreservesProfileOnDelete()throws Exception {
  var s=link(target);var logged=login(target);
  mvc.perform(put("/api/v1/user/"+target.getId()).cookie(access).with(csrf()).contentType("application/json").content(accountBody(target,true,"WAREHOUSE"))).andExpect(status().isOk());
  mvc.perform(get("/api/v1/auth/me").cookie(logged.getResponse().getCookie("ACCESS_TOKEN"))).andExpect(status().isUnauthorized());
  mvc.perform(delete("/api/v1/user/"+target.getId()).cookie(access).with(csrf())).andExpect(status().isConflict());assertTrue(staff.existsById(s.getId()));
 }
 @Test void staffManagementRequiresAdmin()throws Exception {
  var sales=login(target).getResponse().getCookie("ACCESS_TOKEN");
  mvc.perform(get("/api/v1/staff").cookie(sales)).andExpect(status().isForbidden());
  mvc.perform(post("/api/v1/staff").cookie(sales).with(csrf()).contentType("application/json").content(body(target.getId(),"ACTIVE","SALES"))).andExpect(status().isForbidden());
 }
 @Test void cannotDisableLastAdmin()throws Exception {
  for(var u:users.findAll()){if(!u.getId().equals(admin.getId()))u.setActive(false);}users.flush();
  var s=link(admin);
  mvc.perform(put("/api/v1/user/"+admin.getId()).cookie(access).with(csrf()).contentType("application/json").content(accountBody(admin,false,"ADMIN"))).andExpect(status().isConflict()).andExpect(jsonPath("$.code").value("LAST_ADMIN"));
 }
 @Test void profileUpdateCannotChangeAccountPermissionsOrCredentials() throws Exception {
  var s=link(target);var logged=login(target);String hash=target.getPasswordHash(),email=target.getEmail(),username=target.getUserName();long version=target.getAuthVersion();
  String attack=body(admin.getId(),"TERMINATED","ADMIN");
  attack=attack.substring(0,attack.length()-1)+",\"password\":\"NewPassword!\",\"username\":\"hacked\",\"email\":\"hacked@example.test\",\"isActive\":false}";
  mvc.perform(put("/api/v1/staff/"+s.getId()).cookie(access).with(csrf()).contentType("application/json").content(attack))
   .andExpect(status().isOk()).andExpect(jsonPath("$.data.roles[0]").value("SALES"))
   .andExpect(jsonPath("$.data.status").value("ACTIVE")).andExpect(jsonPath("$.data.accountActive").value(true));
  assertEquals(hash,target.getPasswordHash());assertEquals(email,target.getEmail());assertEquals(username,target.getUserName());assertEquals(version,target.getAuthVersion());assertEquals(target.getId(),s.getUser().getId());
  mvc.perform(get("/api/v1/auth/me").cookie(logged.getResponse().getCookie("ACCESS_TOKEN"))).andExpect(status().isOk());
 }
 @Test void validatesPhoneAndSixCharacterPassword() throws Exception {
  String key=UUID.randomUUID().toString().substring(0,12);
  String base=body(null,"ACTIVE","SALES");
  base=base.substring(0,base.length()-1)+",\"username\":\""+key+"\",\"email\":\""+key+"@example.test\",\"password\":\"123456\"}";
  for(String phone:new String[]{"","012345678","01234567890","1123456789","0abcdefgh9"}) {
   mvc.perform(post("/api/v1/staff").cookie(access).with(csrf()).contentType("application/json")
    .content(base.replace("0901234567",phone))).andExpect(status().isBadRequest());
  }
  mvc.perform(post("/api/v1/staff").cookie(access).with(csrf()).contentType("application/json")
   .content(base.replace("123456\"}","12345\"}"))).andExpect(status().isBadRequest());
  var created=mvc.perform(post("/api/v1/staff").cookie(access).with(csrf()).contentType("application/json")
   .content(base)).andExpect(status().isOk()).andReturn();
  var profile=staff.findAll().stream().filter(s->s.getUser().getEmail().equals(key+"@example.test")).findFirst().orElseThrow();
  assertTrue(passwords.matches("123456",profile.getUser().getPasswordHash()));
  mvc.perform(put("/api/v1/staff/"+profile.getId()).cookie(access).with(csrf()).contentType("application/json")
   .content(body(profile.getUser().getId(),"ACTIVE","SALES").replace("0901234567","1234567890"))).andExpect(status().isBadRequest());
 }
 @Test void createsAccountWithSalesRoleRegardlessOfSubmittedRoles()throws Exception {
  String key=UUID.randomUUID().toString().substring(0,12);
  String req=body(target.getId(),"TERMINATED","ADMIN");req=req.substring(0,req.length()-1)+",\"username\":\""+key+"\",\"email\":\""+key+"@example.test\",\"password\":\"Password123!\"}";
  mvc.perform(post("/api/v1/staff").cookie(access).with(csrf()).contentType("application/json").content(req)).andExpect(status().isOk()).andExpect(jsonPath("$.data.email").value(key+"@example.test"))
   .andExpect(jsonPath("$.data.roles[0]").value("SALES")).andExpect(jsonPath("$.data.roles.length()").value(1))
   .andExpect(jsonPath("$.data.status").value("ACTIVE")).andExpect(jsonPath("$.data.accountActive").value(true))
   .andExpect(jsonPath("$.data.staffCode").doesNotExist());
  mvc.perform(post("/api/v1/staff").cookie(access).with(csrf()).contentType("application/json").content(body(target.getId(),"ACTIVE","USER"))).andExpect(status().isBadRequest());
 }
}
