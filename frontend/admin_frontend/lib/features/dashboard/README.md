# Dashboard & Báo cáo

## Phạm vi

Dashboard quản trị dùng dữ liệu thật từ GET `/api/v1/dashboard`. Chỉ ADMIN được xem chỉ số tài chính; bảo vệ cả security route hiện có và @PreAuthorize tại controller. Không tạo bảng báo cáo, không thêm hoặc sửa migration và không tạo giao dịch mẫu trong luồng chạy thật.

Gồm Tổng quan, Doanh thu, Đơn hàng, Trả hàng, Sản phẩm, Kho, Khách hàng, Nhập hàng, Ưu đãi. Route /reports vẫn mở tab Doanh thu. Tổng quan chỉ giữ 4 KPI và biểu đồ. Các tab có bảng phân trang ở server; giải thích/chỉ số phụ gập trong “Xem chỉ số tổng hợp & cách tính”.

## Thời gian và chỉ số

- Báo cáo theo ngày Việt Nam (Asia/Ho_Chi_Minh), lấy đủ ngày đầu/cuối bằng khoảng [00:00 ngày đầu, 00:00 ngày sau ngày cuối). So sánh kỳ trước liền kề cùng số ngày. Ngày không phát sinh vẫn có điểm 0 trên biểu đồ; kỳ trước bằng 0 không tạo tỷ lệ tăng trưởng vô hạn.
- Doanh thu thuần hàng = giá gốc snapshot dòng hàng đã giao − giảm giá sản phẩm − discount_amount (gồm voucher và thành viên) − giá trị trả của đơn từng giao đã nhận trong kỳ. Phí giao hàng tách riêng. Đơn chưa giao không tạo doanh thu dù đã thanh toán.
- Giá vốn ròng = unit_cost snapshot dòng giao − giá vốn hàng trả INTACT của đơn từng giao. Hàng hỏng không đảo giá vốn. Lợi nhuận gộp chưa trừ vận hành, thuế, phí giao hàng/cổng thanh toán.
- Trả do giao thất bại chưa từng ghi nhận doanh thu không giảm doanh thu/giá vốn. Tiền hoàn phiếu này vẫn tính vào tiền đã hoàn khi completed_at có giá trị, gồm phí giao nếu nghiệp vụ trả đã tính.
- AOV = tiền hàng sau giảm trên đơn giao / số đơn giao, trước hàng trả, không gồm vận chuyển.
- Thu tiền theo lần chuyển PENDING → CONFIRMED trong order_histories hoặc sự kiện thanh toán về sau hủy; hoàn đơn hủy theo sự kiện “Đã hoàn …”, hoàn hàng trả theo completed_at. Mỗi đơn lấy MIN timestamp để tránh cộng lặp callback/lịch sử trạng thái. Không dùng updated_at hoặc ngày tạo đơn thay ngày thu/hoàn. Đây là thống kê vận hành theo lịch sử hiện có, chưa phải sổ kế toán/gateway settlement.
- Số đơn đặt theo ngày tạo, gồm chờ/hủy. Tỷ lệ hủy là trạng thái hiện tại của nhóm tạo trong kỳ. Phân bố có cả RETURNED. Đơn giao là nhóm riêng theo lần giao thành công đầu tiên trong lịch sử.
- Sản phẩm nhóm theo SKU, cộng tất cả dòng và trừ trả nhận trong kỳ. Giảm giá cấp đơn và tiền hoàn cấp phiếu phân bổ theo giá trị dòng; dòng cuối nhận phần dư làm tròn để đối chiếu với tổng. Lọc danh mục chỉ tác động bảng; KPI toàn cửa hàng.
- Kho hiện tại: có thể bán = tồn − giữ, ngưỡng cảnh báo ≤ 5, gồm SKU tạm ngừng bán. Giá trị tồn = tồn × cost_price hiện tại. Không áp dụng khoảng ngày vào tồn kho.
- Công nợ NCC hiện tại trên toàn bộ phiếu POSTED = max(total − returned − tổng supplier_payments, 0). Phiếu nháp/hủy không tính. Nhập ròng nhóm phiếu theo posted_at trong kỳ trừ credit trả NCC lũy kế hiện tại. Đã trả tiền/còn nợ của phiếu không phải dòng tiền chi trong kỳ.
- Người mua tài khoản theo user_id; khách vãng lai theo số điện thoại đặt hàng đã chuẩn hóa khoảng trắng. Không tự gộp hai loại định danh. Thiếu cả hai thì không tính thành người mới. Mới/quay lại dùng lần thanh toán đầu tiên trong toàn bộ lịch sử sẵn có, không giới hạn mẫu 90 ngày. Dùng chung số điện thoại có thể đại diện nhiều người; không coi đây là nhận diện cá nhân tuyệt đối.
- Ưu đãi theo snapshot đơn: voucher tách phần thành viên, giảm giá sản phẩm chỉ ghi tổng mức giảm, không bịa tên chiến dịch không được snapshot. Một đơn có thể nằm nhiều nhóm, không cộng lượt giữa nhóm. Mức giảm chưa đảo hàng trả; không kết luận tác động tăng trưởng.

## Request và response

GET `/api/v1/dashboard?start=2026-10-01&end=2026-10-15&section=overview&page=0&size=10`

- start/end bắt buộc, ISO yyyy-MM-dd, start ≤ end, tối đa 366 ngày, không quá hôm nay Việt Nam.
- section: overview/revenue/orders/returns/products/inventory/customers/purchases/promotions, mặc định overview.
- q tối đa 200 ký tự, category tối đa 100; status chỉ nhận PENDING/CONFIRMED/SHIPPED/DELIVERED/CANCELLED/RETURNED.
- page 0–1000000; size 1–100. Sai kiểu, giá trị, enum hoặc thiếu ngày trả 400 trước truy vấn database.
- Response ApiResponse.data: summary, previous, trend, current, distribution, categories, table(columns/rows/totalElements/note), warnings, timezone, generatedAt.
- Báo cáo tổng hợp, tìm kiếm, xếp hạng và phân trang trên SQL Server. Tham số SQL bind; q được escape ký tự wildcard. Không tải toàn bộ giao dịch xuống frontend.
- Các giá trị tổng hợp dùng BigDecimal phía backend. FE hiển thị KPI/biểu đồ làm tròn đến đồng; ô tiền trong bảng giữ tối đa 2 chữ số thập phân để không mất phần phân bổ.

## Trạng thái giao diện

Mặc định AnalyticsRepository gọi API thật; AnalyticsRepository.demo chỉ dùng fixture kiểm thử. Đang tải hiện tiến trình và ẩn nội dung cũ; lỗi có Thử lại, không thay bằng dữ liệu mẫu. Kết quả request cũ không đè lên khoảng ngày/tab mới. Tìm kiếm đang chờ được tách theo tab. Sao chép CSV tải từng trang 100 dòng của bộ lọc đã chụp lúc bấm, không chỉ trang đang nhìn; escape công thức khi nhập vào spreadsheet. Nếu lỗi giữa chừng thì không sao chép báo cáo thiếu. CSV nhiều trang phản ánh dữ liệu tại các lần đọc, không phải snapshot giao dịch duy nhất khi cửa hàng đang cập nhật.

## Lưu ý dữ liệu thời gian và giới hạn

Các entity Order/OrderHistory/ReturnRequest hiện dùng LocalDateTime UTC với Hibernate TIMESTAMP và jdbc.time_zone=UTC. Trên JVM múi giờ Việt Nam, driver ghi DATETIME2 lệch −7 giờ so với giá trị entity. Repository báo cáo bù offset JVM để đọc cùng thời gian logic với các entity rồi mới nhóm ngày Việt Nam; Instant/DATETIMEOFFSET của phiếu nhập không bù. Đã kiểm thử ranh giới 23:59:59/00:00 trên SQL Server local. Môi trường dùng múi giờ cố định UTC hoặc Việt Nam; nếu đổi timezone máy chủ giữa các lần ghi dữ liệu hoặc nhập SQL ngoài Hibernate, cần chuẩn hóa/đối soát timestamp trước khi dùng cho báo cáo. Không tự viết lại lịch sử giao dịch.

Đơn cũ thiếu mốc thanh toán/giao được cảnh báo và không tự đoán ngày. Không có dữ liệu truy cập web để tính conversion, không có đủ chi phí để tính lợi nhuận ròng. Truy vấn tổng hợp dựa vào lịch sử hiện có; khi thay nội dung sự kiện thu/hoàn trong OrderService cần cập nhật bộ nhận diện tương ứng. Tồn và công nợ luôn là ảnh chụp hiện tại.

## Kiểm thử

DashboardWorkflowTest: chạy các truy vấn của cả 9 tab trên SQL Server, đối chiếu nhiều dòng/trả hàng, giao thất bại, ranh giới ngày Việt Nam, phân trang và escape tìm kiếm; dữ liệu fixture rollback.
DashboardApiTest: validation request và phân quyền.
dashboard_workflow_test.dart: luồng màn hình và nghiệp vụ mẫu.
dashboard_live_test.dart: lỗi API không hiện mẫu, phản hồi cũ không đè báo cáo mới, phân trang server và xuất CSV nhiều trang.
