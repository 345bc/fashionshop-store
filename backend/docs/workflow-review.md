# Rà soát workflow — 09/10/2026

Phạm vi: đọc controller, security, service cho user/customer, catalog/variant, cart, checkout, VNPay, order, return, inventory và goods receipt. Các điểm chưa sửa dưới đây được xác định từ code; chưa thử khai thác trên database thật.

## Đã xử lý

1. `UserController`: EMPLOYEE từng được tạo/sửa user với bộ role tùy ý, bao gồm ADMIN, hoặc đổi mật khẩu user khác. POST/PUT/DELETE user hiện chỉ dành cho ADMIN. Test method security xác nhận EMPLOYEE bị từ chối trước khi gọi service.
2. Cookie `checkout_allowed=true` do browser tự đặt không chứng minh đã qua giỏ hàng. Đổi sang cookie ký HMAC và HttpOnly; Next server kiểm tra quote trước khi cấp quyền truy cập checkout.
3. Trang thành công yêu cầu phase `paid` do server cấp sau khi xác minh token đơn và trạng thái PAID với backend. Đây là kiểm soát truy cập trang; dữ liệu trang `/order-success` hiện vẫn là UI minh họa, chưa nối đơn thực tế.
4. Trang tài khoản xác minh phiên với backend; không chỉ dựa trên sự tồn tại của cookie. Backend lỗi thì trả 503, không cho truy cập.

## Còn cần xử lý

- **Giữ tồn hàng loạt**: public checkout có thể tạo nhiều đơn với checkoutKey khác nhau và giữ tồn 5 phút cho mỗi đơn. Chưa có giới hạn tần suất hoặc số đơn PENDING theo khách/IP/số điện thoại. Middleware trang không chặn người gọi API trực tiếp. Cần giới hạn trên backend; duy trì mua không đăng nhập.
- **Đổi danh tính biến thể có lịch sử giao dịch**: `ProductVariantService.save` chặn đổi tồn và giá vốn khi có hàng, nhưng vẫn gán lại product/size/color. Phiếu bán/nhập/giữ tồn đang tham chiếu variantId có thể bị chuyển sang biến thể khác. Cần chặn đổi tổ hợp khi có tồn/giữ hàng hoặc đã được tham chiếu trong giao dịch; tạo biến thể mới cho tổ hợp mới.
- **JWT dùng email làm subject**: filter tìm user theo email hiện tại trong database. Nếu email cũ của một tài khoản còn token được cấp lại cho tài khoản khác, token cũ có thể ánh xạ sang tài khoản mới. Nên dùng userId bất biến làm subject và kiểm tra token version/thu hồi khi thay thông tin xác thực.
- **Tra cứu không có OTP/rate limit**: mã đơn ngẫu nhiên và số điện thoại giới hạn khả năng truy cập, DTO không trả địa chỉ hay token. Tuy nhiên đây chưa phải xác minh quyền sở hữu bằng OTP. Cần OTP trước khi mở thông tin cá nhân hoặc thao tác đơn, và giới hạn tần suất tra cứu.
- **Hoàn tiền là ghi nhận thủ công**: endpoint `refunded`/`complete` cho nhân viên đánh dấu hoàn tiền theo workflow nhưng chưa đối soát giao dịch hoàn thực tế. Đây là tính năng thủ công hiện tại; không nên hiển thị như hoàn tiền tự động qua VNPay.

## Các bước đã có kiểm tra backend

- Giá bán checkout lấy từ variant; client không truyền giá hoặc trạng thái thanh toán.
- Checkout status/cancel/payment cần token đơn. Cart thao tác theo principal đăng nhập, không nhận userId do client lựa chọn.
- VNPay kiểm tra chữ ký, merchant, mã đơn, tiền, transaction status, chống ghi nhận trùng. Return xác minh local chỉ chạy khi bật chế độ local sandbox.
- Giao hàng chỉ từ CONFIRMED + PAID; giao thành công chỉ từ SHIPPED; hủy trực tiếp chỉ trước xuất kho.
- Trả hàng: khóa đơn cha, không vượt lượng mua, nhận sau APPROVED, hoàn tất sau RECEIVED; phiếu lặp không nhập tồn lần hai.
- Phiếu nhập chỉ POST từ DRAFT; sửa chỉ DRAFT; thanh toán/trả NCC chỉ POSTED. Đảo phiếu đã nhập kiểm tra biến động tiếp theo và hàng đã giữ.
- Điều chỉnh tồn kiểm tra expected quantity, khóa variant và không giảm dưới reserved quantity. Sửa variant không được sửa trực tiếp stock/reserved.

Không kết luận hệ thống đã chống được mọi hình thức bypass. Kiểm tra giao dịch đồng thời và gateway thực tế cần môi trường tích hợp riêng.
