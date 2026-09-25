# Zella Fashion Shop — Redesign 2026

## Phạm vi
Chỉ chỉnh sửa giao diện và chức năng phía khách hàng. Không thêm trang Admin/Nhân viên.

## Các thay đổi chính
- Thiết kế lại Header theo phong cách modern editorial, responsive.
- Mega menu sản phẩm nhỏ gọn, chia nhóm rõ ràng và có featured collection.
- Trang chủ mới: hero, category edit, best sellers, editorial section, benefits.
- Trang sản phẩm gọn hơn; bộ lọc chỉ gồm Loại sản phẩm, Kích cỡ, Giá.
- Tìm kiếm sản phẩm hoạt động qua `/products?q=...`.
- Product card mới, wishlist interaction, responsive grid.
- Trang chi tiết sản phẩm mới: gallery, màu, size, số lượng, size guide, add-to-cart modal, review section.
- Đăng nhập/đăng ký căn giữa màn hình và đồng bộ giao diện.
- Làm lại Profile, Orders tracking, Loyalty, Purchase History + đánh giá sản phẩm.
- Làm lại Cart, Checkout, Order Success, Support Chat.
- Chuẩn hóa font: dùng Geist từ Next.js; bỏ dependency font icon Google bên ngoài, chuyển icon sang lucide-react.

## Kiểm tra
- `tsc --noEmit`: PASS
- `eslint src --max-warnings=0`: PASS
- `next build` không chạy được trong môi trường đóng gói do thiếu binary SWC Linux trong node_modules cũ và môi trường không có network để tải lại. Source TypeScript và ESLint đã được kiểm tra sạch.

## Chạy project
```bash
npm install
npm run dev
```

Sau đó mở `http://localhost:3000`.
