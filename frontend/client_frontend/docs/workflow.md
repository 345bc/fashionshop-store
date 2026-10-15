# Bảo vệ luồng truy cập

Next.js 16 dùng `src/proxy.ts` thay cho `middleware.ts`.

- `/checkout`: yêu cầu cookie `zella_checkout_flow` có chữ ký hợp lệ và chưa hết hạn.
- `/order-success`: thêm yêu cầu phase `paid`. Server chỉ cấp phase này sau khi backend xác minh token đơn, trạng thái đơn và thanh toán.
- `/profile`, `/orders`, `/purchase-history`, `/loyalty`: xác minh phiên qua backend `/auth/me`. Khi access token hết hạn, proxy gọi POST `/auth/refresh` với cookie refresh và CSRF, rồi chuyển cookie mới về trình duyệt. Refresh không hợp lệ chuyển sang đăng nhập; backend không truy cập được trả 503.
- `/order-tracking` công khai cho khách vãng lai; API tra cứu vẫn kiểm tra mã đơn và số điện thoại, chỉ trả dữ liệu giới hạn.

Nút đặt hàng gọi `POST /api/checkout-flow`. Server kiểm tra giỏ bằng backend rồi cấp cookie HttpOnly, SameSite=Lax, Secure trên production, có thời hạn 1 giờ. Cookie `checkout_allowed` cũ không còn được sử dụng. ReturnURL VNPay cùng tab vẫn đi qua được khi cookie hợp lệ.

## Cấu hình

Thêm `WORKFLOW_COOKIE_SECRET` vào môi trường server frontend, tối thiểu 32 ký tự ngẫu nhiên. Local đã có trong `.env.local` (không commit). Deploy tạo secret riêng, cùng giá trị trên các instance; đổi secret sẽ kết thúc các phiên đặt hàng cũ. Không dùng tiền tố `NEXT_PUBLIC_` cho secret này.

Proxy chỉ kiểm soát quyền vào trang. Người dùng vẫn có thể gọi API tạo phiên với giỏ hợp lệ. Quyền thao tác đơn, chữ ký VNPay, kiểm tra chuyển trạng thái, khóa tồn kho và chống xử lý trùng thuộc backend. Không xem việc đi qua trang là bằng chứng đã thanh toán.

Các điểm cần tiếp tục xử lý sau rà soát: giới hạn tần suất tạo đơn giữ hàng/tra cứu, giới hạn việc đổi product/size/color của biến thể đã có giao dịch, đối soát hoàn tiền thật. Các endpoint ghi nhận hoàn tiền hiện là xác nhận thủ công bởi nhân viên.
