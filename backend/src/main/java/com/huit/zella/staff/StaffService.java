package com.huit.zella.staff;

import com.huit.zella.auth.*;
import com.huit.zella.user.*;
import com.huit.zella.enums.RoleEnum;
import com.huit.zella.common.exception.BusinessException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.http.HttpStatus;
import org.springframework.data.domain.*;

@Service
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class StaffService {
    private final StaffRepository staff;
    private final UserRepository users;
    private final UserService accounts;

    @Transactional(readOnly = true)
    public Page<StaffResponse> list(String q, Boolean active, Pageable page) {
        return staff.search(q == null || q.isBlank() ? null : q.trim(), active, page).map(StaffResponse::from);
    }

    @Transactional
    public StaffResponse create(CreateStaffRequest req) {
        var roles = java.util.Set.of(RoleEnum.SALES);
        var account = accounts.createUser(new CreateUserRequest(req.username(), req.password(), req.email(), roles));
        Staff s = new Staff();
        s.setUser(users.findById(account.id()).orElseThrow());
        apply(s, new StaffRequest(req.fullName(), req.position(), req.phone(), req.hiredDate()));
        staff.saveAndFlush(s);
        return StaffResponse.from(s);
    }

    @Transactional
    public StaffResponse update(Long id, StaffRequest req) {
        Staff s = require(id);
        apply(s, req);
        staff.saveAndFlush(s);
        return StaffResponse.from(s);
    }

    private void apply(Staff s, StaffRequest req) {
        s.setFullName(req.fullName().trim());
        s.setPosition(req.position());
        s.setPhone(req.phone());
        s.setHiredDate(req.hiredDate());
    }

    private Staff require(Long id) {
        return staff.findById(id).orElseThrow(() -> new BusinessException(HttpStatus.NOT_FOUND, "STAFF_NOT_FOUND", "Không tìm thấy nhân sự"));
    }
}
