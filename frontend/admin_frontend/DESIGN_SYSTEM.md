# Zella Design System - Hướng dẫn Thiết kế UI/UX

Tài liệu này quy chuẩn hoá phong cách thiết kế giao diện (UI) và trải nghiệm (UX) dựa trên trang **Quản lý Tài khoản (Users Screen)**. Mục tiêu là để các lập trình viên khi làm các trang khác (Sản phẩm, Đơn hàng, Khách hàng...) có thể đối chiếu và code theo một chuẩn chung, mang lại cảm giác cao cấp (Premium SaaS) như Linear, Stripe hay Vercel.

---

## 1. Triết lý Thiết kế (Design Philosophy)
- **Tối giản & Thoáng đãng:** Xoá bỏ các đường viền (border) thừa thãi, đặc biệt là viền dọc trong bảng (Excel style).
- **Phân cấp Rõ ràng:** Sử dụng màu sắc mờ (opacity 0.1) cho các Badge trạng thái thay vì những dải màu đậm chói mắt.
- **Micro-Interactions:** Mọi thao tác trỏ chuột (Hover), chuyển trang đều phải mượt mà, sử dụng thời gian `AppAnimations.fast` (150ms).

---

## 2. Cấu trúc Chuẩn Của Một Trang (Page Anatomy)
Bất kỳ một màn hình Quản lý danh sách nào (Sản phẩm, Khách hàng, Đơn hàng...) cũng phải tuân thủ trình tự Layout (từ trên xuống dưới) như sau:

1. **Header (Tiêu đề & CTA)**
2. **Spacing 32px**
3. **Thanh công cụ (Toolbar - Search & Filters)**
4. **Spacing 24px**
5. **Main Container (Bảng dữ liệu)**
   - Segmented Tabs (Tuỳ chọn)
   - Table Header
   - Table Rows
   - Pagination (Phân trang)

Tất cả bọc trong `SingleChildScrollView` với `padding: const EdgeInsets.all(32.0)`.

---

## 3. Quy chuẩn Chi tiết từng Component

### A. Header Component (`UsersHeader`)
- **Trái:** Tiêu đề lớn (`headlineMedium`, in đậm) và Dòng mô tả ngắn (Subtext màu `textSecondary`).
- **Phải:** Nút Action. 
  - Nút phụ (Xuất dữ liệu, Filter mở rộng) dùng `OutlinedButton.icon`.
  - Nút chính (Tạo mới) dùng `ElevatedButton.icon` (Nền đen, chữ trắng theo `AppTheme`).

### B. Thanh Công Cụ (Toolbar)
Bọc trong Container bo góc `12px`, viền `borderLight`, nền `surface`.
- Khung Search: `TextField` với `prefixIcon: Icon(Icons.search)`. Chiếm không gian lớn nhất (`Expanded(flex: 2)`).
- Dropdown Filter: Xoá bỏ gạch chân (`DropdownButtonHideUnderline`), bo góc `8px`, viền mờ.

### C. Container Bảng dữ liệu (The Table Block)
Khối này bắt buộc phải bọc trong một `Container` nền màu Trắng (`Colors.white`), bo góc `12px`, viền `borderLight`, có shadow cực nhẹ:
```dart
boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.02),
    blurRadius: 10,
    offset: const Offset(0, 4),
  ),
]
```

#### C.1 Segmented Tabs (Bảng điều hướng trạng thái)
- Nếu dữ liệu có chia trạng thái (Tất cả, Đang xử lý, Hoàn thành...), bắt buộc dùng Tabs ở đầu bảng thay vì nhét vào Dropdown.
- Tab đang chọn: Viền dưới (bottom border) dày 2px màu `primary`. Chữ in đậm màu `text`. Badge đếm số nền đen chữ trắng.
- Tab chưa chọn: Chữ màu `textSecondary`, Badge nền xám nhạt (`surface`).

#### C.2 Table Header
- Text size `12px`, in đậm `w600`, màu `textSecondary`. Toàn bộ viết hoa chữ cái đầu.

#### C.3 Table Rows (Dữ liệu)
- **Tuyệt đối không dùng DataGrid/DataTable mặc định** nếu nó vẽ ra viền dọc. Dùng `ListView.separated` với dải phân cách ngang.
- **Hiệu ứng Hover:** Row phải được bọc bởi `InkWell` với `hoverColor: AppTheme.surface`.
- **Action Menu (⋮):** Dành riêng khoảng không gian `width: 48` ở cuối hàng để đặt `UserActionMenu`. Mọi thao tác (Sửa, Xoá, Khoá) đều giấu trong dấu 3 chấm này, không rải rác icon ra ngoài.

#### C.4 Pagination (Phân trang)
- Đặt dưới cùng của Table Container, ngăn cách với hàng cuối cùng bằng 1 nét mảnh (Divider).
- Text trạng thái bên trái: *"Hiển thị 1-10 trong số..."*
- Cụm nút bên phải: Kích thước khối vuông bo góc `32x32`. Trang hiện tại tô màu `primary` chữ trắng.

---

## 4. UI/UX States (Các trạng thái Hệ thống)
Khi lập trình trang mới, tuân thủ nghiêm ngặt 3 trạng thái sau:
1. **Loading State:** Khi call API, hiển thị `ShimmerList` (hiệu ứng khung xương) thay vì xoay vòng tròn Loading.
2. **Empty State:** Dùng `EmptyStateWidget` nếu bảng không có dữ liệu (có hình Icon to, và nút "Tạo mới").
3. **Error State:** Dùng `ErrorStateWidget.network` nếu mất kết nối.
4. **Notifications:** Dùng `NotificationHelper.showSuccessSnackbar()` sau khi gọi API Create/Update/Delete thành công.

---

> [!TIP]
> **Cách áp dụng:** Khi thiết kế tính năng mới (ví dụ `ProductsScreen`), hãy copy nguyên khung của `users_screen.dart` và chỉnh sửa các field lại cho phù hợp. Điều này đảm bảo toàn bộ dự án sẽ có sự đồng nhất 100% từ đầu tới cuối.

---

## 5. Quy chuẩn Popups (Modals & Dialogs)
Tất cả các popup (hộp thoại) trong dự án phải được xây dựng dựa trên các base component trong thư mục `lib/widgets/dialogs` nhằm duy trì sự nhất quán.

### A. ZellaDialog (Base Component)
- **Hình dáng (Shape):** Bo góc `12px`.
- **Padding:** Mặc định `24px` cho toàn bộ nội dung.
- Không sử dụng `AlertDialog` hay `SimpleDialog` mặc định của Flutter nếu không bọc lại giao diện.

### B. ZellaConfirmDialog (Popup Cảnh báo/Xoá)
Dùng cho các hành động mang tính phá huỷ (xoá, khoá) hoặc cần xác nhận chắc chắn.
- **Kích thước:** Chiều rộng cố định `400px`.
- **Bố cục nội dung căn giữa (Center Aligned):** 
  - Icon cảnh báo hình tròn lớn ở trên cùng (màu `error` hoặc `warning`, opacity nền 0.1).
  - Tiêu đề (`18px`, in đậm, màu `text`).
  - Nội dung mô tả ngắn (`14px`, màu `textSecondary`).
- **Nút bấm (Actions):** 2 nút chiếm toàn bộ chiều ngang (`Expanded`).
  - Trái: Nút Huỷ (`OutlinedButton`, viền mờ).
  - Phải: Nút Xác nhận (`ElevatedButton`, nền màu đỏ `error` nếu là xoá, nền màu `primary` nếu là xác nhận thường). Kèm theo trạng thái `isLoading`.

### C. ZellaFormDialog (Popup Biểu mẫu)
Dùng cho Thêm Mới, Cập Nhật, hoặc các form nhập liệu nhỏ.
- **Kích thước:** Chiều rộng cố định `480px`.
- **Bố cục nội dung căn trái (Left Aligned):**
  - Tiêu đề ở góc trái trên cùng (`20px`, in đậm, màu `text`).
  - Nội dung là biểu mẫu gồm các `TextField` (Bo góc `8px`, viền `borderLight`). Khoảng cách giữa các ô là `16px`.
- **Nút bấm (Actions):** 2 nút nằm ở góc phải dưới (`MainAxisAlignment.end`).
  - Nút Huỷ: `OutlinedButton`.
  - Nút Lưu: `ElevatedButton`, nền màu `primary`. Cả hai nút có padding `horizontal: 24`, `vertical: 16`. Kèm trạng thái `isLoading`.

