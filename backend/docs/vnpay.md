# Thanh toán VNPay sandbox

## Cấu hình backend

Đăng ký sandbox: https://sandbox.vnpayment.vn/devreg/

VNPay cung cấp `TmnCode` và `HashSecret`. Điền vào `backend/src/main/resources/application-local.properties` (không commit file chứa khóa thật):

```properties
app.payment.vnpay.enabled=true
app.payment.vnpay.ipn-required=false
app.payment.vnpay.tmn-code=<TmnCode>
app.payment.vnpay.hash-secret=<HashSecret>
app.payment.vnpay.payment-url=https://sandbox.vnpayment.vn/paymentv2/vpcpay.html
app.payment.vnpay.return-url=http://localhost:3000/checkout
app.order.payment-simulation.enabled=false
```

Hoặc dùng biến môi trường: `VNPAY_ENABLED`, `VNPAY_TMN_CODE`, `VNPAY_HASH_SECRET`, `VNPAY_PAYMENT_URL`, `VNPAY_RETURN_URL`.

`enabled=false` tắt checkout thanh toán; không tạo đơn và giữ hàng khi chưa có cấu hình hợp lệ. Sau khi điền cấu hình, khởi động lại backend. Không đặt HashSecret trong frontend hoặc biến `NEXT_PUBLIC_*`.

## Đăng ký IPN

VNPay gọi URL backend để thông báo kết quả, không gọi được `localhost` trên máy bạn. Dùng URL HTTPS công khai trỏ tới backend local và đăng ký với VNPay:

```text
https://<backend-public-host>/api/v1/payment/vnpay/ipn
```

IPN nhận **GET**, trả JSON trực tiếp theo chuẩn VNPay (`RspCode`, `Message`). Không bọc kết quả IPN trong `ApiResponse`.

`return-url` là trang khách quay lại sau thanh toán, mặc định `/checkout`. Cổng thanh toán mở cùng tab để bảo toàn đơn/token đang lưu trong sessionStorage.

Local sandbox: đặt `app.payment.vnpay.ipn-required=false`. Khi trình duyệt quay về, checkout gửi các tham số VNPay và token đơn tới backend để xác minh chữ ký, merchant, mã đơn, số tiền và trạng thái giao dịch trước khi cập nhật. Cách thử này phụ thuộc khách quay lại trang checkout; đóng trình duyệt có thể khiến đơn hết hạn dù đã thanh toán. Chỉ cho phép gateway sandbox và ReturnURL localhost/127.0.0.1.

Khi deploy: đặt `app.payment.vnpay.ipn-required=true` hoặc `VNPAY_IPN_REQUIRED=true` (mặc định). Khi đó ReturnURL không cập nhật thanh toán; chỉ IPN hợp lệ cập nhật đơn. Đăng ký IPN HTTPS công khai với VNPay. Cờ này khác `enabled`: giữ `enabled=true` để bật thanh toán.

## Luồng đã nối

- Khách đăng ký hoặc khách vãng lai đặt hàng; backend tính giá và giữ tồn 5 phút. Thử lại cùng `checkoutKey` không tạo thêm đơn.
- `POST /api/v1/checkout/orders/{code}/payment` cần `X-Checkout-Token`, tạo URL ký bằng HMAC-SHA512, `vnp_TxnRef` là ID đơn, số tiền nhân 100 và thời gian theo GMT+7. `vnp_ExpireDate` bằng thời hạn giữ hàng của đơn.
- Một đơn dùng một URL đã lưu. Nếu thanh toán thất bại/hủy tại VNPay, khách có thể hủy đơn và tạo lại từ giỏ để có mã giao dịch mới; không tạo nhiều yêu cầu thanh toán khác nhau cho cùng đơn.
- IPN kiểm tra chữ ký, merchant, đơn, tiền và cả `vnp_ResponseCode=00` / `vnp_TransactionStatus=00`. Callback thành công tự xác nhận đơn; callback lặp trả `02`, không cập nhật lần nữa.
- Callback thất bại không xác nhận trả tiền; đơn vẫn chờ đến thời hạn giữ hàng. Hết hạn tự hủy và trả tồn đã giữ.
- Tiền được thông báo thành công sau khi đơn đã hủy: `REFUND_PENDING`, không mở lại đơn hoặc xuất kho. Hoàn tiền vẫn do nhân viên xử lý, chưa gọi API refund VNPay tự động.
- Dữ liệu địa chỉ dùng Province Open API v2 qua `/api/address` của Next.js, tỉnh/thành phố → phường/xã.

## Migration

V25 giữ nguyên để không làm lệch checksum nếu đã chạy. V26 đổi tên cột `payment_account_number` sang `payment_merchant_code`; cột `payment_checkout_url` được dùng lại. Flyway tự chạy theo thứ tự khi khởi động backend.

## Thử trên sandbox

1. Chạy frontend và backend đã cấu hình. Local sandbox đặt `ipn-required=false`; khi dùng IPN đặt `true` và đăng ký IPN HTTPS công khai.
2. Đặt đơn từ checkout, bấm thanh toán VNPay.
3. Chọn thẻ nội địa NCB theo thông tin thử nghiệm trong tài liệu demo chính thức:
   - Số thẻ: `9704198526191432198`
   - Chủ thẻ: `NGUYEN VAN A`
   - Ngày phát hành: `07/15`
   - OTP: `123456`
4. Sau thanh toán kiểm tra đơn chuyển `PAID` / `CONFIRMED`. Với local sandbox phải quay lại checkout trong cùng tab; khi bật IPN kiểm tra đăng ký IPN, URL công khai, merchant và cấu hình HashSecret nếu đơn vẫn chờ.
5. Thử hủy thanh toán, hết hạn 5 phút, callback lặp, sai chữ ký và sai tiền. Thẻ sandbox dùng cho sandbox, không thử bằng thẻ thật.

Tài liệu tích hợp: https://sandbox.vnpayment.vn/apis/docs/thanh-toan-pay/pay.html

Thẻ thử nghiệm: https://sandbox.vnpayment.vn/apis/vnpay-demo/

Chưa có kiểm tra giao dịch sandbox thực tế trong lần triển khai này; cần thông tin tài khoản sandbox và IPN đã đăng ký để kiểm tra toàn bộ luồng.
