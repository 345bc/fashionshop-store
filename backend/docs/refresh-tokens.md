# Phiên đăng nhập JWT và refresh token

- Access token mặc định 30 phút. Refresh token mặc định 7 ngày kể từ lần đăng nhập, không kéo dài hạn tuyệt đối khi gia hạn.
- Cấu hình `app.auth.jwt.access-token-minutes`, `app.auth.jwt.refresh-token-days`, `app.auth.jwt.cookie-secure`; biến môi trường tương ứng `JWT_ACCESS_TOKEN_MINUTES`, `JWT_REFRESH_TOKEN_DAYS`, `JWT_COOKIE_SECURE`.
- Khi deploy HTTPS, dùng `JWT_COOKIE_SECURE=true`. Local HTTP dùng false. `application-local.properties` không được commit; các cấu hình còn thiếu đã được đồng bộ từ file chính, giữ nguyên các giá trị local hiện có.
- Migration V30 tạo `refresh_sessions`. Token gốc chỉ gửi qua cookie HttpOnly, SameSite=Lax, không nằm trong JSON. DB lưu SHA-256 của token 256 bit, liên kết user ID và bản băm mật khẩu tại lúc đăng nhập.
- POST `/api/v1/auth/refresh` được gọi khi access token hết hạn, vẫn yêu cầu CSRF. Trả thông tin người dùng và hai cookie mới. Không dùng refresh token để gọi API nghiệp vụ.
- Token đổi mã khi gia hạn. Cửa sổ 10 giây cho request đồng thời cho phép token trước nhận lại cùng token kế tiếp; không tiếp tục xoay trong cửa sổ này. Mã kế tiếp được suy ra bằng HMAC có phân biệt mục đích, không lưu token thô trong DB.
- Token trước bị dùng lại sau cửa sổ đồng thời sẽ thu hồi phiên. Token hết hạn, bị thu hồi, tài khoản khóa hoặc đổi mật khẩu đều không thể gia hạn.
- Đăng nhập lại thu hồi phiên refresh hiện có trên thiết bị. POST `/auth/logout` yêu cầu CSRF, thu hồi phiên và xóa cả hai cookie, kể cả khi access token đã hết hạn. Access JWT đã sao chép trước đăng xuất vẫn có hạn tối đa bằng TTL access; logout không phải danh sách chặn mọi JWT đã phát hành.
- Client gom các lỗi 401 đồng thời vào một lần refresh và thử lại mỗi request tối đa một lần. Không refresh cho 403, login hoặc logout; logout đợi refresh đang chạy để tránh cookie mới xuất hiện sau đăng xuất.
- Proxy kiểm tra trang tài khoản cũng gia hạn khi cần; refresh giả không được qua proxy. Không thay thế kiểm tra quyền ở backend.
- Admin Flutter tự gia hạn khi token hết hạn hoặc API trả 401, cập nhật hai token theo cơ chế lưu phiên hiện có và tiếp tục kiểm tra quyền admin.
- Khởi động lại backend để chạy migration. Đăng nhập lại một lần để nhận refresh cookie; phiên cũ chỉ có access cookie không tự tạo refresh token.

Tham khảo bảo vệ cookie và CSRF: [OWASP Session Management](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html), [Spring Security CSRF](https://docs.spring.io/spring-security/reference/servlet/exploits/csrf.html).
