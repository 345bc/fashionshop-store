# Tài khoản khách hàng: đơn hàng, đánh giá, điểm thưởng

## Dữ liệu và quyền truy cập

- Tận dụng `orders`, `order_items`, `customer_profiles`, `product_reviews`, `vouchers`, bảng trả hàng và giỏ hàng hiện có.
- Thêm `reward_transactions` để lưu lịch sử cộng/trừ điểm và khóa tham chiếu chống xử lý trùng. Không lấy số điểm, giá hàng hoặc userId từ frontend.
- Mọi API `/api/v1/me/**` yêu cầu đăng nhập; khách hàng chỉ thao tác dữ liệu thuộc tài khoản lấy từ principal. Đơn của khách chưa đăng nhập tiếp tục tra cứu bằng mã đơn và số điện thoại ở luồng tra cứu riêng.

## Đơn hàng và lịch sử mua

- Danh sách phân trang, lọc theo sáu trạng thái hệ thống: PENDING, CONFIRMED, SHIPPED, DELIVERED, CANCELLED, RETURNED.
- Lịch sử mua gồm đơn DELIVERED hoặc RETURNED. Chi tiết hiển thị người nhận, tiền hàng, phí vận chuyển, giảm giá, tổng và lịch sử trạng thái thật.
- Khách chỉ hủy đơn PENDING chưa thanh toán. Hủy hoặc hết hạn giải phóng lượt voucher đã giữ. Không tự hủy đơn đã thanh toán.
- Mua lại lấy variant/quantity từ đơn thuộc tài khoản, thêm vào giỏ bằng khóa UUID chống thêm trùng khi retry; giá/tồn hiện tại được kiểm tra lại. Không tự tạo đơn mới.
- Yêu cầu trả hàng chỉ sau khi giao; số lượng không vượt số mua trừ các phiếu đang xử lý. Cửa hàng duyệt/nhận/hoàn tiền bằng workflow trả hàng hiện có.
- Nhận trả toàn bộ hàng chuyển đơn RETURNED; hoàn tiền xong tất cả phiếu mới chuyển REFUNDED. Trả một phần giữ DELIVERED.

## Đánh giá

- Giao diện viết/sửa đánh giá nằm trực tiếp trong Đơn hàng của tôi (`/orders`), theo từng sản phẩm đủ điều kiện. Không còn mục lịch sử mua riêng; URL `/purchase-history` chuyển về `/orders`.
- Đơn đã giao, đã thanh toán, sản phẩm chưa trả hết mới được đánh giá. Không đánh giá sản phẩm khác đơn.
- Một đánh giá mỗi orderItem; gửi lại cập nhật bản ghi đó. Sao 1–5, nội dung tối đa 1.000 ký tự. Đánh giá bị ẩn không được khách sửa để tự công khai lại.
- Trang sản phẩm đọc điểm trung bình, tổng và danh sách đánh giá thật, bỏ đánh giá bị ẩn; có API phân trang để xem tiếp.

## Điểm thưởng

- **10.000đ tiền hàng trước giảm giá = 1 điểm, lấy phần nguyên**, không tính phí vận chuyển. Ví dụ 519.000đ = 51 điểm.
- Chỉ cộng ở DELIVERED + PAID. Khóa tham chiếu ORDER-EARN-{id} ngăn cộng lặp. Đơn khách không đăng nhập không tích điểm.
- Nhận hàng trả: tính lại `floor((subtotal - tiền hàng đã nhận trả trước giảm giá) / 10000)`; thu hồi chênh lệch. Khóa ORDER-RETURN-{id} ngăn thu hồi lặp.
- **Số dư không âm**. Nếu điểm cần thu hồi vượt số dư, đưa số dư về 0 và lưu phần thiếu trong `customer_profiles.reward_point_adjustment`. Điểm đơn sau bù phần điều chỉnh trước, còn lại mới cộng số dư.
- FE hiển thị lời giải thích khi adjustmentPoints > 0; đây là điều chỉnh điểm, không phải tiền phải thanh toán. Ví dụ còn 20 điểm, thu hồi 50: số dư 0, cần điều chỉnh 30. Đơn mới được 50: số dư 20, phần điều chỉnh về 0.
- Lịch sử phân trang, mặc định một tháng gần nhất; lọc ngày theo múi giờ Việt Nam, dữ liệu lưu UTC. Lịch sử ghi biến động điểm cùng số dư thực tế sau giao dịch.
- `total_spending` tăng theo tiền hàng thực trả, giảm theo tiền hàng được hoàn. Giữ hạng thành viên hiện có; chưa đặt quy tắc nâng hạng mới.
- Không tự cộng lại điểm các đơn cũ đã giao trước khi triển khai ledger, tránh cộng trùng số dư cũ.

## Đổi ưu đãi và sử dụng

- Mẫu ưu đãi dùng bảng vouchers với is_redeemable=true; không dùng trực tiếp mã mẫu để thanh toán.
- Khóa customer profile khi đổi, kiểm tra đủ điểm, tạo voucher riêng thuộc khách, trừ điểm và lưu lịch sử trong cùng transaction. Khóa UUID chống trừ điểm trùng khi retry.
- Các mức đổi ban đầu: 200/500/1.000 điểm đổi 20K/50K/100K; 800 điểm đổi giảm 10% tối đa 80K; 150 điểm đổi gói quà và thiệp. Điều kiện đơn tối thiểu lưu trên voucher và hiển thị FE.
- Voucher đã đổi có hạn 30 ngày, một lượt dùng, không chuyển giữa tài khoản. Danh sách voucher có phân trang.
- Nút Áp dụng ở checkout gọi backend quote giá thực; chỉ kiểm tra, không giữ lượt. Khi tạo đơn backend kiểm tra lại và giữ lượt voucher dưới khóa database.
- VNPay sử dụng totalAmount sau giảm giá. Response trả subtotal/shippingFee/discountAmount riêng; FE không suy ra phí vận chuyển bằng chênh lệch tổng.
- Hoàn hàng trả theo tỷ lệ tiền hàng sau giảm giá; phiếu trả cuối xử lý phần làm tròn. Voucher đã dùng cho đơn đã thanh toán không được cấp lại tự động.
- Gói quà ghi vào ghi chú đơn cho nhân viên xử lý; hoàn tiền tiếp tục theo quy trình xác nhận của cửa hàng, chưa gọi API hoàn tiền tự động.

## API

| API | Chức năng |
| --- | --- |
| GET /me/orders?status=ALL&purchases=false&page=0&size=10 | Danh sách đơn hoặc lịch sử mua |
| GET /me/orders/{id} | Chi tiết đơn của mình |
| POST /me/orders/{id}/cancel | Hủy trước thanh toán |
| POST /me/orders/{id}/reorder | Mua lại, body `{key}` |
| POST /me/orders/{id}/returns | Yêu cầu trả, body `{orderId,reason,items:[{orderItemId,quantity}]}` |
| PUT /me/orders/{id}/items/{itemId}/review | Ghi/sửa đánh giá `{rating,comment}` |
| GET /me/loyalty | Số dư, điểm cần điều chỉnh, ưu đãi và trang voucher đầu |
| GET /me/loyalty/vouchers?page=0&size=10 | Voucher đã đổi |
| GET /me/loyalty/history?from=YYYY-MM-DD&to=YYYY-MM-DD&page=0&size=10 | Lịch sử điểm |
| POST /me/loyalty/redeem | Đổi ưu đãi `{rewardId,key}` |
| POST /checkout/orders/voucher | Quote ưu đãi `{code,items:[{variantId,quantity}]}` |
| GET /product/{id}/reviews?page=0&size=20 | Đánh giá công khai |

Các đường dẫn có tiền tố `/api/v1`. API list dùng `ApiResponse<PageResponse<T>>`, chỉ số trang bắt đầu 0, thuộc tính `number`.

## Tính tiền checkout

- POST `/api/v1/checkout/orders/quote` nhận items, shippingMethod và voucherCode; lấy giá sản phẩm và hạng thành viên từ backend.
- Thành viên STANDARD giảm 5%, SILVER 7%, GOLD 10% tiền hàng. Khách chưa đăng nhập không hưởng giảm thành viên.
- Coupon tính trên tiền hàng sau giảm thành viên. Quote không giữ lượt voucher; tạo đơn kiểm tra lại và giữ lượt trong transaction.
- Phí vận chuyển lấy từ cấu hình backend, mặc định 0đ cho cả STANDARD và EXPRESS. FE hiển thị breakdown do backend trả về.
- V29 lưu giảm thành viên, tỷ lệ và giảm phí vận chuyển trên đơn để số tiền không đổi khi cấu hình thay đổi.
- FE chặn đặt hàng khi mã đã nhập chưa được áp dụng, quote đang tải hoặc backend từ chối voucher. Xóa mã để đặt hàng không dùng voucher.
- Ô voucher và nút Áp dụng chỉ mở khi đã điền họ tên, địa chỉ, tỉnh/thành phố, phường/xã và số điện thoại hợp lệ; căn hộ và ghi chú không bắt buộc.

## Quản lý hoàn hàng ở admin

- Nút `Quản lý hoàn hàng` thay cho `Tạo đơn hàng`, mở dialog danh sách đơn có yêu cầu hoàn hàng.
- GET `/api/v1/order-return/management?q=&status=ALL&page=0&size=10` dành cho ADMIN và EMPLOYEE; tìm theo mã đơn, tên hoặc số điện thoại, lọc theo trạng thái phiếu hoàn hàng.
- Mỗi đơn chỉ xuất hiện một lần dù có nhiều phiếu. Danh sách trả số phiếu, số đang chờ duyệt, các trạng thái và thời điểm yêu cầu mới nhất.
- Nhấp vào đơn để mở chi tiết và sử dụng các thao tác duyệt, nhận hàng, ghi nhận hoàn tiền hiện có.

## Migration

- V27 thêm ledger và quyền sở hữu voucher; đã giữ nguyên nội dung/checksum bản được áp dụng.
- V28 đổi order.points_earned sang INT, bổ sung phần điểm cần điều chỉnh và ràng buộc số dư không âm; chuẩn hóa cột nullable của voucher cũ.
- Khởi động lại backend để Flyway chạy migration còn thiếu. Không sửa checksum bằng repair, không xóa dữ liệu.
