package com.huit.zella.role;
import com.huit.zella.auth.*;
import com.huit.zella.common.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.HttpStatus;
@Service @RequiredArgsConstructor @PreAuthorize("hasRole('ADMIN')")
public class RoleCreateService {
 private final RoleRepository roles;
 @Transactional public Response create(RoleCreateRequest request) {
  String code=request.roleCode().trim().toUpperCase(java.util.Locale.ROOT);
  if(code.startsWith("ROLE_") || java.util.Set.of("EMPLOYEE","CUSTOMER").contains(code)) throw new BusinessException(HttpStatus.BAD_REQUEST,"INVALID_ROLE_CODE","Mã role thuộc nhóm mã cũ hoặc có tiền tố ROLE_");
  if(roles.findByRoleCodeIgnoreCase(code).isPresent()) throw duplicate();
  Role role=new Role();role.setRoleCode(code);role.setRoleName(request.roleName().trim());role.setDescription(request.description()==null?null:request.description().trim());
  try { roles.saveAndFlush(role); }
  catch(org.springframework.dao.DataIntegrityViolationException e) {throw duplicate();}
  return new Response(role.getId(),role.getRoleCode(),role.getRoleName(),role.getDescription());
 }
 private BusinessException duplicate(){return new BusinessException(HttpStatus.CONFLICT,"ROLE_CODE_EXISTS","Mã role đã tồn tại");}
 public record Response(Long id,String roleCode,String roleName,String description) {}
}
