# Dashboard & Báo cáo — chỉ frontend

## Phạm vi và luồng

Một mục Dashboard & Báo cáo thay cho hai màn hình mock rời rạc. /reports vẫn mở
cùng feature ở phần Doanh thu để giữ tương thích. Gồm Tổng quan, Doanh thu,
Đơn hàng, Trả hàng, Sản phẩm, Kho, Khách hàng, Nhập hàng, Ưu đãi.

- Thời gian: hôm nay, 7/30/90 ngày, khoảng tùy chọn; tính đủ cả ngày đầu/cuối.
- So sánh kỳ trước liền kề cùng số ngày. Không hiển thị % tăng trưởng hoặc đường
  so sánh nếu kỳ trước thiếu dữ liệu mẫu; mẫu chỉ có 90 ngày.
- KPI có tooltip giải thích và nhấp để đi vào báo cáo tương ứng.
- Biểu đồ tương tác xem số theo ngày; bảng tìm kiếm, lọc cục bộ theo trạng thái đơn
  hoặc danh mục, phân trang và xem số đầy đủ của dòng trong dialog.
- Sao chép CSV lấy tất cả các dòng của bộ lọc, không chỉ trang đang xem; có tiêu đề,
  khoảng ngày, ghi chú. Đây là sao chép clipboard, không phải download file Excel.
- Tổng quan chỉ có 4 KPI chính và biểu đồ doanh thu. Bảng, đối chiếu và cảnh báo
  thuộc phần chi tiết của từng tab; không trưng toàn bộ nghiệp vụ ở trang đầu.
- Các tab chi tiết không hiển thị dãy KPI mặc định. Chỉ số tổng hợp và giải thích
  được gập trong “Xem chỉ số tổng hợp & cách tính”; mở khi cần. Bộ lọc kỳ dùng
  dropdown và thông báo dữ liệu mẫu gọn, phần giải thích dài nằm ở tooltip.

Tất cả doanh số/đơn/phiếu nhập là dữ liệu mẫu cùng một nguồn, được tính toán nhất quán.
Không gọi API, không sửa BE/database, không tạo entity backend. Dữ liệu số lượng
tồn kho là ảnh chụp hiện tại mẫu.

## Cấu trúc

- data/models: read models/DTO báo cáo, enums phần/khoảng ngày, summary/table.
- data/repositories: dữ liệu mẫu Order/OrderItem, Return, Receipt và SKU.
- data/analytics_calculations: hàm tổng hợp dùng chung cho KPI/biểu đồ/bảng.
- data/analytics_report_builder: các bảng theo nghiệp vụ, nhóm/xếp hạng trước định dạng.
- presentation/providers: khoảng ngày, so sánh, phần chọn, tìm/lọc/phân trang, CSV.
- presentation/widgets: bộ lọc, KPI, biểu đồ, panel nghiệp vụ và bảng dùng chung.
- presentation/screens: ghép trang. ReportsScreen chỉ là wrapper cho route cũ.

Khi làm BE, tận dụng Order/OrderItem, OrderHistory, ReturnRequest/ReturnItem,
Product/Variant, InventoryMovement, GoodsReceipt/Item, SupplierPayment/Return/Refund,
CustomerProfile/User, Voucher và Promotion/Product. Báo cáo là truy vấn tổng hợp,
không phải lý do để thêm entity mới. BE nên trả DTO tổng hợp và phân trang thay vì
tải toàn bộ dữ liệu giao dịch về FE.

## Định nghĩa chỉ số

### Doanh thu và lợi nhuận gộp

1. Tiền hàng trước giảm giá = giá niêm yết snapshot × SL các dòng thuộc đơn đã giao,
   theo thời điểm giao thực tế (không theo ngày tạo đơn hoặc trạng thái thanh toán).
2. Trừ giảm sản phẩm và voucher đã phân bổ cho các dòng giao trong kỳ.
3. Trừ tiền hàng trả đã nhận trong kỳ theo giá thực trả. Phiếu trả chờ duyệt/chưa nhận
   chưa giảm doanh số. Nhận trả kỳ này có thể thuộc đơn giao kỳ trước.
4. Doanh thu thuần hàng = (1) − giảm sản phẩm − voucher − tiền hàng trả.
   Phí vận chuyển tách riêng, không gộp vào chỉ số này.
5. Giá vốn ròng = snapshot unitCost lúc bán × SL đã giao − giá vốn hàng trả nguyên
   vẹn nhận lại. Hàng hỏng không vào kho bán và không đảo giá vốn.
6. Lợi nhuận gộp = doanh thu thuần hàng − giá vốn ròng. Chưa trừ vận hành, thuế,
   phí cổng thanh toán/chi phí giao hàng; không gọi là lợi nhuận ròng.
7. AOV đơn giao = tiền hàng sau giảm / số đơn giao, trước hàng trả, không gồm vận chuyển.

### Thu và hoàn tiền

- Thực thu: toàn bộ thanh toán thành công trong kỳ, gồm phí vận chuyển. Đơn đã thu
  nhưng chưa giao chưa phải doanh thu giao hàng; đơn đã hủy vẫn có lịch sử thu.
- Đã hoàn: hoàn đơn hủy + hoàn hàng trả theo thời điểm thực chi hoàn tiền.
  Refund pending không tính là đã hoàn. Callback trùng phải tính đúng một lần khi làm BE.
- Thu − hoàn chỉ là tiền thu khách sau hoàn, không phải số dư quỹ: chưa trừ chi NCC
  hoặc chi phí khác. Bộ mẫu chưa có chi phí/cổng thanh toán thật.
- Trả hàng ở dashboard là phiếu đã nhận; không mô tả tất cả phiếu nháp/chờ duyệt.

### Đơn, khách, sản phẩm

- Số đơn đặt: theo ngày tạo; gồm đơn chờ, hủy. Tỷ lệ hủy: trạng thái hiện tại của
  nhóm đơn tạo trong kỳ. Đơn giao trong kỳ là một nhóm khác (theo ngày giao).
- Sản phẩm: SL bán ròng và doanh thu ròng trừ trả nhận trong kỳ, có thể âm.
  Xếp theo doanh thu thuần. Lọc danh mục tác động bảng, KPI vẫn toàn cửa hàng.
- Người mua: khóa người mua duy nhất có thanh toán trong kỳ, gồm khách vãng lai;
  không đếm mỗi đơn vãng lai thành một người. Mới/quay lại dựa trên lần thanh toán
  đầu tiên trong mẫu 90 ngày; BE cần toàn bộ lịch sử và cách định danh hợp lệ.
- Không coi lượng tài khoản đăng ký là lượng người mua. Không suy diễn conversion
  website vì chưa có dữ liệu truy cập/session/giỏ bỏ quên.

### Kho, nhập hàng, ưu đãi

- Kho hiện tại: có thể bán = tồn − giữ, giá trị tồn = tồn × costPrice hiện tại.
  SKU ≤ 5 có cảnh báo; bằng 0 là hết hàng. Không lọc theo ngày hoặc giả lập tồn lịch sử.
- Giá trị nhập ròng của nhóm phiếu: phiếu POSTED trong kỳ trừ credit trả NCC hiện tại
  của những phiếu đó; không phải dòng nhập/trả ròng theo thời điểm credit phát sinh.
- Công nợ hiện tại: toàn bộ phiếu POSTED, max(total − credit − paid, 0).
  Draft/cancelled không tính nợ. Nếu paid > nghĩa vụ sau trả hàng là khoản phải thu
  lại NCC, không hiển thị là nợ âm. Bộ mẫu không có khoản phải thu này.
- Số đã trả tiền phiếu là lũy kế hiện tại, không phải tiền chi trong kỳ. Khi BE có
  SupplierPayment/Refund theo ngày, có thể thêm báo cáo dòng tiền NCC.
- Voucher/khuyến mãi: giảm trên đơn giao; lượt dùng mã theo đơn có thanh toán trong kỳ.
  Các nhóm có thể giao nhau, không cộng lượt giữa voucher và promotion. Giảm trong
  bảng ưu đãi chưa đảo theo hàng trả; doanh thu thuần đã trừ hàng trả riêng.
- Doanh thu gắn ưu đãi không chứng minh hiệu quả tăng trưởng do ưu đãi.

## Giới hạn và triển khai sau

Bộ mẫu 90 ngày, một SKU mỗi đơn, tiền VND nguyên. Chưa có giá vốn thay đổi theo
lịch sử, nhiều kho, thuế, chi phí vận hành hoặc gateway. Không tạo chỉ số bịa cho
những dữ liệu chưa có. Kho/công nợ/cảnh báo là số hiện tại, độc lập bộ lọc ngày.

Khi nối BE: giờ UTC -> local, làm tròn BigDecimal, loại đơn chưa giao khỏi doanh thu,
giữ snapshot giá và giá vốn, phân bổ voucher/hàng trả, dùng timestamp giao/nhận trả/
thu/hoàn thật, kiểm soát quyền xem báo cáo nhạy cảm theo roles hiện có. Chính sách
ghi nhận trên đây là thống kê vận hành đề xuất, không phải sổ kế toán chính thức.
