# Voucher & Khuyến mãi — thiết kế FE, tận dụng entity hiện có

## Phạm vi

Trang chung có hai thẻ mở trang quản lý Voucher hoặc Khuyến mãi, giống Thuộc tính
sản phẩm. Có quay lại, hover, tìm kiếm, lọc trạng thái, phân trang, dialog
thêm/sửa/chi tiết rộng 2/3 màn hình và bật/tắt có lý do.

Dữ liệu và danh sách sản phẩm đều là mẫu trong bộ nhớ. Tải lại ứng dụng khôi phục mẫu.
Chưa gọi API, chưa sửa BE/DB, chưa áp dụng giảm giá vào sản phẩm/đơn hàng.

## Entity dùng lại

| Entity / bảng hiện có | Nghiệp vụ |
| --- | --- |
| Voucher / vouchers (V4) | Mã duy nhất, description, discount_type, discount_value, discount_amount, min_order_amount, usage_limit, used_count, is_active, start_date, end_date |
| Promotion / promotion (V2) | Tên, mô tả, phần trăm giảm, thời gian bắt đầu/kết thúc, trạng thái bật/tắt |
| PromotionProduct / promotionproduct (V2) | Liên kết chương trình với sản phẩm; khóa productId + promotionId duy nhất |
| Product / ProductVariant | Sản phẩm được áp dụng và giá bán của biến thể |
| Order / OrderItem (V5 và các migration sau) | orders.voucher_id, discount_amount; giá chốt của dòng hàng, trạng thái thanh toán và hạn giữ đơn để xác định lượt sử dụng |
| CustomerProfile / User | Người mua đăng ký hoặc khách vãng lai; nhân viên thao tác |
| OrderHistory | Dùng lịch sử đơn hiện có để theo dõi thanh toán/hủy và điều tra lượt dùng mã |

Không yêu cầu tạo VoucherUsage, VoucherHistory, PromotionHistory hay entity riêng
cho trạng thái. Lịch sử dùng voucher lấy từ đơn gắn voucher_id. CampaignHistoryModel
và VoucherUsageModel chỉ là DTO/dữ liệu trình bày FE, không phải đề xuất bảng mới.
Lịch sử thao tác chương trình trong UI là mẫu local; chưa cam kết lưu lịch sử đó ở BE.

Voucher không có cột name riêng: tên trên mẫu FE là nhãn trình bày; khi nối API
có thể dùng description hoặc code, không cần thêm entity/cột chỉ để khớp mẫu.
Trường discount_amount chưa rõ nghĩa trong schema; cần kiểm tra service/quy ước
trước khi ánh xạ thành trần giảm maxDiscountAmount. Không tự đổi nghĩa dữ liệu cũ.

## Nghiệp vụ Voucher

1. Khách nhập mã tại checkout. Mã duy nhất không phân biệt hoa thường; chuẩn hóa
   A–Z/0–9/_/-, dài 3–50 ký tự. Mã đã sử dụng không đổi để giữ đối chiếu đơn.
2. Giảm phần trăm hoặc số tiền; phần trăm 1–100, tiền giảm > 0; đơn tối thiểu >= 0.
   Trần giảm nếu có phải > 0. Tổng lượt nếu khai báo phải > 0 và >= lượt đã dùng.
   used_count không nhập/sửa thủ công từ giao diện.
3. Tiền giảm tính trên tiền hàng sau khuyến mãi, không gồm phí vận chuyển;
   giảm không vượt tiền hàng đủ điều kiện. Mỗi đơn tối đa một voucher.
   Đây là quy tắc chung đề xuất, không tạo thêm cấu hình/entity cộng dồn.
4. Tận dụng luồng online 5 phút: đơn PENDING gắn voucher_id và còn hạn là một suất
   đang giữ. Tạo đơn khóa voucher, kiểm tra used_count + suất đang giữ < usage_limit.
   Cùng giao dịch giữ suất và giữ hàng để tránh vượt quota.
5. Thanh toán trước hạn cập nhật lượt đã dùng một lần, cùng chuyển trạng thái đơn.
   Timeout/hủy chưa trả tiền chuyển đơn sang CANCELLED: đơn không còn chiếm suất.
   Không cần bảng giữ suất riêng, nhưng phải khóa và kiểm tra trạng thái ở BE.
6. Callback muộn không kích hoạt lại voucher/đơn. Callback trùng không tăng used_count
   lần nữa; dùng trạng thái và transaction id của đơn hiện có để bảo đảm idempotency.
7. Khách vãng lai dùng mã như khách đăng ký. Chưa làm hạn mức mỗi người mua,
   mã cá nhân hoặc đổi điểm để giữ mô hình hiện tại đơn giản.
8. Đề xuất không trả lại lượt đã USED khi hủy đơn đã thanh toán/trả hàng;
   chỉ giải phóng suất chưa thanh toán. Khi làm BE cần chốt chính sách này.
   Hoàn tiền dựa trên số thực thu và giá dòng hàng sau phân bổ giảm.
9. Lịch sử sử dụng: danh sách Order có voucher_id tương ứng, kèm mã đơn,
   người mua, thời gian thanh toán và discount_amount. Không tạo entity usage mới.

## Nghiệp vụ Khuyến mãi

1. Giảm phần trăm tự động cho sản phẩm chọn qua PromotionProduct;
   áp dụng tất cả biến thể đang hoạt động của sản phẩm. Không cần nhập mã.
2. Phần trăm 1–100 và ít nhất một sản phẩm; không trùng liên kết.
3. Một sản phẩm có nhiều chương trình hiệu lực: chọn mức giảm tốt nhất,
   không cộng dồn phần trăm; nếu bằng nhau chọn id ổn định để xử lý nhất quán.
4. Không ghi đè basePrice/price, stock hoặc costPrice. Tính giá bán hiệu lực
   từ chương trình và giữ giá đã chốt trên OrderItem khi đặt đơn.
5. Chương trình hết hạn/chỉnh sửa trong 5 phút chờ thanh toán không đổi tổng tiền
   của đơn đã tạo. Đơn mới tính lại giá theo thời điểm tạo.
6. Voucher giảm tiếp trên tiền hàng đã giảm theo quy tắc chung nêu trên.
7. Trả hàng hoàn theo giá thực trả, không theo giá niêm yết, không vượt tiền đã thu.

## Trạng thái và quy tắc chung

- Start inclusive, end exclusive; start < end.
- Đang diễn ra: bật và start <= now < end.
- Sắp diễn ra: bật nhưng chưa đến start. Đã tắt: chưa hết hạn nhưng tắt.
- Hết hạn: now >= end, dù bật hay tắt. Hết lượt: voucher đạt quota trong thời gian hiệu lực.
- Bật lại không đổi thời hạn hoặc số lượt dùng; UI cập nhật trạng thái mỗi phút.
- Khi làm BE lấy giờ server, lưu UTC và hiển thị local. Tiền dùng BigDecimal,
  làm tròn theo VND; FE mẫu dùng số nguyên VND và phần trăm nguyên.
- Dùng quyền ADMIN/EMPLOYEE theo project. Người thao tác lấy từ phiên xác thực.
- Không sửa migration đã chạy. Chỉ bổ sung trường vào entity hiện có khi nghiệp vụ
  thực tế chứng minh cần; không tạo bảng/abstraction mới để phục vụ mẫu giao diện.
- V4 có points_required/is_redeemable; đổi điểm để sau, không mở rộng entity ở bước này.

## Cấu trúc FE

data/models chứa VoucherModel/PromotionModel, enums và DTO hiển thị.
data/repositories chứa dữ liệu mẫu. presentation/providers xử lý tìm/lọc/phân trang,
validate và cập nhật mẫu. presentation/screens là trang chung và trang quản lý;
presentation/dialogs là form/chi tiết/xác nhận bật tắt.

Routes: /promotions, /vouchers, /promotion-programs.
