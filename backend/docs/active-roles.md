# Vai trò và phiên đăng nhập

Các role hợp lệ: `ADMIN`, `SALES`, `WAREHOUSE`, `CUSTOMER_SUPPORT`, `MARKETING`, `USER`.
Chức danh (`position`) không cấp quyền. Tài khoản mới mặc định một role; Admin có thể cấp nhiều role trong quản lý tài khoản.

- JWT chỉ chứa `activeRole`, không chứa danh sách `roles`.
- Login, refresh và `/api/v1/auth/me` trả `roles` được cấp và `activeRole`.
- Một role: đăng nhập dùng role đó. Nhiều role: `activeRole=null`, `roleSelectionRequired=true`; JWT chưa có authority nghiệp vụ.
- Phiên chưa chọn role chỉ dùng `/auth/me`, `/auth/select-role`, refresh, logout và CSRF; gọi API nghiệp vụ trực tiếp trả 403 `ROLE_SELECTION_REQUIRED`. Refresh giữ trạng thái chưa chọn role.
- `POST /api/v1/auth/select-role` với `{ "role": "WAREHOUSE" }` yêu cầu đăng nhập và CSRF; backend lấy quyền từ database rồi cấp access/refresh token mới.
- Authority chỉ là `ROLE_<activeRole>`; quyền không cộng dồn từ các role khác.
- Mỗi request kiểm tra tài khoản còn hoạt động và role đang dùng còn được cấp. Refresh giữ activeRole, từ chối khi role bị thu hồi.
- JWT gắn `sid` với refresh session và `authVersion` của tài khoản. Chuyển role/đăng xuất thu hồi phiên cũ; đổi quyền, khóa tài khoản hoặc đổi mật khẩu thu hồi tất cả phiên. Các phiên không được hồi phục bằng token cũ sau khi mở khóa.

## Phạm vi API

| Role | Phạm vi |
| --- | --- |
| ADMIN | Quản lý tài khoản/role và toàn bộ nghiệp vụ quản trị |
| SALES | Tra cứu khách, xem sản phẩm, xử lý giao/hủy đơn đúng trạng thái |
| WAREHOUSE | Xem kho, lập/sửa phiếu nhập nháp, quản lý biến thể/NCC, tiếp nhận hàng trả |
| CUSTOMER_SUPPORT | Tra cứu khách và đơn, lập yêu cầu hoàn hàng |
| MARKETING | Quản lý voucher/promotion, nội dung và ảnh sản phẩm |
| USER | Các chức năng mua hàng và tài khoản cá nhân hiện có |

Xác nhận nhập kho, thanh toán NCC, hoàn tiền, duyệt/từ chối hoàn hàng, điều chỉnh tồn và chỉnh giá sản phẩm dành cho ADMIN.
Frontend lọc menu, chặn điều hướng và ẩn thao tác tương ứng; backend vẫn kiểm tra độc lập.
Màn hình nhân sự đã sử dụng API thật; chức vụ không tham gia kiểm tra quyền.

## Migration V33

Chuẩn hóa các mã role cũ, chuyển `EMPLOYEE` sang `SALES` và `CUSTOMER` sang `USER`, giữ các quyền cụ thể còn lại.
Admin cần rà soát phân công lại nhân viên cũ theo công việc thực tế.
Refresh session cũ bị thu hồi vì chưa có activeRole; người dùng cần đăng nhập lại sau cập nhật.

Marketing sửa nội dung qua `PATCH /api/v1/product/{id}/content`, không cập nhật giá, danh mục, NCC, size guide hoặc trạng thái sản phẩm.

## Quản lý nhân sự và migration V34

`staff_profiles.user_id` là khóa ngoại duy nhất tới `users.id`. Khách hàng không cần hồ sơ nhân sự.

- ADMIN quản lý qua `GET/POST /api/v1/staff`, `PUT /api/v1/staff/{id}`.
- Thêm nhân sự từ form tạo tài khoản và hồ sơ trong một transaction; backend luôn gán SALES, trạng thái ACTIVE và cho phép đăng nhập. Không liên kết tài khoản có sẵn trong luồng tạo. ADMIN cấp thêm/đổi role ở chỉnh sửa.
- Nhân sự cần ít nhất một role nội bộ; cho phép thêm USER khi tài khoản có nhu cầu mua hàng.
- Trạng thái làm việc được giữ trong hồ sơ; form chỉnh sửa hiện chỉ sửa thông tin cơ bản. Khóa/mở tài khoản thực hiện độc lập ở trang Tài khoản.
- ADMIN sửa thông tin cơ bản trong dialog nhân sự; sửa tài khoản, vai trò, trạng thái đăng nhập và mật khẩu ở trang Tài khoản. Backend chặn khóa/thu hồi ADMIN hoạt động cuối cùng.
- Tài khoản gắn nhân sự không được xóa qua API user; giữ hồ sơ. Audit không ghi mật khẩu.
- V34 thêm trạng thái nhân sự, số điện thoại, authVersion và trạng thái chọn role cho refresh session. Phiên cũ bị thu hồi, cần đăng nhập lại.

Hồ sơ nhân sự dùng id làm định danh nội bộ và userId để liên kết tài khoản. Tìm kiếm theo họ tên hoặc email; không lưu mã nhân sự, mã cũ hoặc lương.

Admin đăng nhập qua `POST /api/v1/auth/admin/login`: backend từ chối tài khoản không có role nội bộ trước khi phát token. `/auth/login` giữ luồng đăng nhập hiện có của website khách hàng. Cả hai vẫn dùng xác thực mật khẩu, khóa tài khoản và quy tắc chọn activeRole.

Sửa hồ sơ nhân sự chỉ cập nhật fullName, position, phone và hiredDate. Endpoint này không cập nhật tài khoản, mật khẩu, role, trạng thái đăng nhập hoặc liên kết user. Quản lý những thông tin đó qua trang Tài khoản/API user; đổi role/khóa tài khoản/đổi mật khẩu vẫn thu hồi phiên.

V36 loại bỏ bảng staff_audit. Nhân sự không còn ghi lịch sử thay đổi hoặc API lịch sử.
