# Voucher và chương trình giảm giá

## Dữ liệu thật

Admin gọi `/api/v1/campaigns`, dành cho ADMIN/MARKETING (theo activeRole). Không còn dữ liệu mẫu trong bộ nhớ.
Trang Voucher có hai nhóm: Voucher nhập mã và Voucher đổi điểm. Trang Khuyến mãi quản lý giảm giá tự động.

## Voucher nhập mã

- Một đơn dùng tối đa một mã. FIXED giảm số tiền; PERCENT giảm phần trăm, có thể giới hạn mức giảm.
- Điều kiện gồm trạng thái, thời gian, giá trị hàng tối thiểu và tổng lượt dùng. Giá trị hàng đã trừ promotion; voucher giảm tiếp sau ưu đãi thành viên, không giảm phí vận chuyển.
- Tạo đơn khóa voucher và giữ lượt cùng giao dịch giữ hàng. Hủy/timeout đơn chưa thanh toán giải phóng lượt; thanh toán trùng không tăng lần nữa. Lượt đã thanh toán không hoàn lại khi trả hàng.
- Admin không sửa trực tiếp số lượt. Không đổi mã hoặc nhóm voucher khi đã có lượt dùng/đổi.

## Voucher đổi điểm

- Admin tạo/sửa mẫu ưu đãi: tên, mã nội bộ, điểm cần đổi nguyên dương, loại ưu đãi, giá trị, điều kiện, thời gian mở đổi, số lượt đổi và bật/tắt.
- Các loại: FIXED, PERCENT và GIFT (gói quà và thiệp, giá trị giảm bằng 0).
- Mã nội bộ của mẫu không nhập trực tiếp tại checkout. Khách đủ điểm đổi mẫu để nhận mã riêng gắn với tài khoản, dùng một lần, có hạn 30 ngày kể từ khi đổi.
- Khóa hồ sơ điểm và mẫu trước khi kiểm tra. Trừ điểm, tăng lượt đổi và cấp mã trong một transaction. Lặp cùng redemption key chỉ trả lại mã đã cấp; không trừ điểm/lượt thêm.
- Mẫu bị tắt, hết hạn, hết lượt hoặc thiếu điểm đều bị chặn ở backend. Khách khác không sử dụng được mã đã cấp.
- Sửa/tắt mẫu không sửa quyền lợi, ngày hết hạn hay trạng thái mã đã cấp. Admin không chỉnh mã cá nhân qua danh mục mẫu.
- Chi tiết mẫu hiển thị 50 lần đổi gần nhất: mã cấp, khách, thời gian, điểm và quyền lợi lúc đổi. Lịch sử liên kết bắt đầu từ V32; mã cũ không có nguồn mẫu không được tự suy đoán.

## Promotion

- Giảm phần trăm tự động cho sản phẩm được chọn hoặc sản phẩm mới tạo trong 7 ngày; áp dụng mọi biến thể.
- Chương trình đầu tiên: **Ưu đãi sản phẩm mới — 5%**, bật sẵn. Sản phẩm vừa tạo tự tham gia; đủ 7 ngày tự hết hưởng mức giảm.
- Start inclusive, end exclusive. Một sản phẩm trùng nhiều chương trình lấy phần trăm lớn nhất, không cộng dồn; hòa chọn ID nhỏ hơn.
- Không ghi đè giá gốc, tồn kho hay giá vốn. Card/details, cart/checkout/order dùng cùng service định giá; giá gốc và giá giảm được hiển thị riêng.
- Đơn lưu giá dòng sau promotion và giá gốc để hoàn tiền đúng giá đã thu, tích/điều chỉnh điểm trên tiền hàng trước giảm giá.
- Đơn chờ thanh toán giữ nguyên giá đã chốt dù chương trình bị sửa/tắt/hết hạn.

## API và migration

- GET `/campaigns/voucher`, GET `/campaigns/promotion`, GET `/campaigns/products`.
- GET `/{kind}/{id}`, POST `/{kind}`, PUT `/{kind}/{id}`, PATCH `/{kind}/{id}/state` (enabled).
- kind = voucher hoặc promotion; voucher request có redeemable và pointsRequired.
- V31 bổ sung phạm vi promotion, tên voucher, snapshot giá gốc và tạo chương trình 5%. V32 liên kết mã đã cấp với mẫu ưu đãi.
- Không sửa migration đã chạy. Khởi động lại backend để Flyway áp dụng phần còn thiếu.
