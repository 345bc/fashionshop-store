"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Image from "next/image";
import Link from "next/link";

export default function CheckoutPage() {
  const router = useRouter();
  const [shipping, setShipping] = useState("standard");
  const [payment, setPayment] = useState("cod");
  const [voucher, setVoucher] = useState("");
  const [discount, setDiscount] = useState(0);
  const [errors, setErrors] = useState<Record<string,string>>({});
  const [form, setForm] = useState({ name: "", phone: "", email: "", city: "", district: "", address: "" });
  const shippingFee = shipping === "express" ? 45000 : 30000;
  const total = 679000 + shippingFee - discount;

  const update = (key: keyof typeof form, value: string) => { setForm((f) => ({...f,[key]:value})); setErrors((e) => ({...e,[key]:""})); };
  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const next: Record<string,string> = {};
    if (!form.name.trim()) next.name = "Vui lòng nhập họ tên";
    if (!/^0\d{9}$/.test(form.phone.replace(/\s/g,""))) next.phone = "Số điện thoại chưa hợp lệ";
    if (!form.city) next.city = "Vui lòng chọn tỉnh/thành";
    if (!form.address.trim()) next.address = "Vui lòng nhập địa chỉ chi tiết";
    setErrors(next);
    if (Object.keys(next).length === 0) router.push("/order-success");
  };

  const applyVoucher = () => setDiscount(voucher.trim().toUpperCase() === "ZELLA50" ? 50000 : 0);

  return (
    <>
      <Header />
      <main className="main-content modern-main checkout-page-modern">
        <div className="breadcrumb modern-breadcrumb"><Link href="/products">Sản phẩm</Link><span>/</span><span>Thanh toán</span></div>
        <div className="checkout-title-modern"><span className="eyebrow">SECURE CHECKOUT</span><h1>Thanh toán</h1><div><span className="active">1 Thông tin</span><span>2 Xác nhận</span></div></div>
        <form className="checkout-grid-modern" onSubmit={submit}>
          <div className="checkout-main-modern">
            <section className="checkout-section-modern">
              <div className="checkout-section-title"><span className="material-symbols-outlined" style={{ fontSize: 18 }}>location_on</span><div><h2>Thông tin giao hàng</h2><p>Nhập thông tin người nhận và địa chỉ giao hàng.</p></div></div>
              <div className="checkout-form-grid">
                <label><span>Họ và tên *</span><input value={form.name} onChange={(e) => update("name",e.target.value)} placeholder="Nguyễn Văn A" />{errors.name && <small>{errors.name}</small>}</label>
                <label><span>Số điện thoại *</span><input value={form.phone} onChange={(e) => update("phone",e.target.value)} placeholder="0901 234 567" />{errors.phone && <small>{errors.phone}</small>}</label>
                <label className="full"><span>Email</span><input type="email" value={form.email} onChange={(e) => update("email",e.target.value)} placeholder="you@example.com" /></label>
                <label><span>Tỉnh / Thành phố *</span><select value={form.city} onChange={(e) => update("city",e.target.value)}><option value="">Chọn tỉnh/thành</option><option>TP. Hồ Chí Minh</option><option>Hà Nội</option><option>Đà Nẵng</option><option>Cần Thơ</option></select>{errors.city && <small>{errors.city}</small>}</label>
                <label><span>Quận / Huyện</span><input value={form.district} onChange={(e) => update("district",e.target.value)} placeholder="Ví dụ: Phú Nhuận" /></label>
                <label className="full"><span>Địa chỉ chi tiết *</span><input value={form.address} onChange={(e) => update("address",e.target.value)} placeholder="Số nhà, tên đường, phường/xã" />{errors.address && <small>{errors.address}</small>}</label>
              </div>
            </section>

            <section className="checkout-section-modern">
              <div className="checkout-section-title"><span className="material-symbols-outlined" style={{ fontSize: 18 }}>local_shipping</span><div><h2>Phương thức vận chuyển</h2><p>Chọn tốc độ giao hàng phù hợp.</p></div></div>
              <div className="checkout-option-list">
                <label className={shipping === "standard" ? "selected" : ""}><input type="radio" name="shipping" checked={shipping === "standard"} onChange={() => setShipping("standard")} /><span className="material-symbols-outlined" style={{ fontSize: 18 }}>inventory_2</span><span><strong>Giao hàng tiêu chuẩn</strong><small>2–4 ngày làm việc</small></span><b>30.000₫</b></label>
                <label className={shipping === "express" ? "selected" : ""}><input type="radio" name="shipping" checked={shipping === "express"} onChange={() => setShipping("express")} /><span className="material-symbols-outlined" style={{ fontSize: 18 }}>local_shipping</span><span><strong>Giao hàng nhanh</strong><small>1–2 ngày làm việc</small></span><b>45.000₫</b></label>
              </div>
            </section>

            <section className="checkout-section-modern">
              <div className="checkout-section-title"><span className="material-symbols-outlined" style={{ fontSize: 18 }}>credit_card</span><div><h2>Phương thức thanh toán</h2><p>Chọn một phương thức để hoàn tất đơn hàng.</p></div></div>
              <div className="checkout-option-list payment-list-modern">
                <label className={payment === "cod" ? "selected" : ""}><input type="radio" name="payment" checked={payment === "cod"} onChange={() => setPayment("cod")} /><span><strong>Thanh toán khi nhận hàng (COD)</strong><small>Thanh toán trực tiếp cho đơn vị vận chuyển</small></span></label>
                <label className={payment === "bank" ? "selected" : ""}><input type="radio" name="payment" checked={payment === "bank"} onChange={() => setPayment("bank")} /><span><strong>Chuyển khoản ngân hàng</strong><small>Thông tin chuyển khoản hiển thị sau khi đặt hàng</small></span></label>
                <label className={payment === "wallet" ? "selected" : ""}><input type="radio" name="payment" checked={payment === "wallet"} onChange={() => setPayment("wallet")} /><span><strong>Ví điện tử / thanh toán online</strong><small>Mô phỏng cổng thanh toán trong bản prototype</small></span></label>
              </div>
            </section>
          </div>

          <aside className="checkout-summary-modern">
            <span className="eyebrow">YOUR ORDER</span><h2>Đơn hàng</h2>
            <div className="checkout-product-mini"><Image src="/assets/images/v7_2020.png" alt="Váy midi Sage Flow" width={72} height={96} /><div><strong>Váy midi Sage Flow</strong><span>Sage · M · SL 1</span><b>679.000₫</b></div></div>
            <div className="voucher-modern"><label>Mã giảm giá</label><div><input value={voucher} onChange={(e) => setVoucher(e.target.value)} placeholder="Thử: ZELLA50" /><button type="button" onClick={applyVoucher}>Áp dụng</button></div>{discount > 0 && <small><span className="material-symbols-outlined" style={{ fontSize: 13 }}>check</span> Đã giảm 50.000₫</small>}</div>
            <div className="summary-line"><span>Tạm tính</span><strong>679.000₫</strong></div>
            <div className="summary-line"><span>Vận chuyển</span><strong>{shippingFee.toLocaleString("vi-VN")}₫</strong></div>
            {discount > 0 && <div className="summary-line discount"><span>Giảm giá</span><strong>-{discount.toLocaleString("vi-VN")}₫</strong></div>}
            <div className="summary-total"><span>Tổng cộng</span><strong>{total.toLocaleString("vi-VN")}₫</strong></div>
            <button className="modern-submit" type="submit">Xác nhận đặt hàng</button>
            <p>Bằng việc đặt hàng, bạn đồng ý với chính sách giao hàng và đổi trả của Zella.</p>
          </aside>
        </form>
      </main>
      <Footer />
    </>
  );
}
