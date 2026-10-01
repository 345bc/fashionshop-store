"use client";

import { useState } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import AccountNav from "@/components/AccountNav";
import Image from "next/image";
import Link from "next/link";

const statuses = ["Tất cả", "Đang xử lý", "Đang giao", "Đã giao"];

export default function OrdersPage() {
  const [status, setStatus] = useState("Tất cả");
  return (
    <>
      <Header />
      <main className="main-content modern-main account-modern-page">
        <div className="breadcrumb modern-breadcrumb"><Link href="/">Trang chủ</Link><span>/</span><span>Đơn hàng của tôi</span></div>
        <div className="account-modern-layout">
          <AccountNav active="orders" />
          <section className="account-content-modern">
            <span className="eyebrow">ORDER TRACKING</span><h1>Đơn hàng của tôi</h1><p className="account-lead">Theo dõi trạng thái xử lý và vận chuyển của từng đơn.</p>
            <div className="order-tabs-modern">{statuses.map((item) => <button key={item} className={status === item ? "active" : ""} onClick={() => setStatus(item)}>{item}</button>)}</div>

            {(status === "Tất cả" || status === "Đang giao") && <article className="order-card-modern">
              <div className="order-card-modern-head"><div><small>ĐƠN HÀNG</small><strong>#ZEL91284</strong><span>18/09/2026 · 2 sản phẩm</span></div><div className="shipping-pill"><span className="material-symbols-outlined" style={{ fontSize: 15 }}>local_shipping</span> Đang giao</div></div>
              <div className="order-timeline-modern">
                <div className="done"><i><span className="material-symbols-outlined" style={{ fontSize: 13 }}>check</span></i><span>Đã xác nhận<small>18/09 · 09:14</small></span></div>
                <div className="done"><i><span className="material-symbols-outlined" style={{ fontSize: 13 }}>inventory</span></i><span>Đã đóng gói<small>19/09 · 14:20</small></span></div>
                <div className="current"><i><span className="material-symbols-outlined" style={{ fontSize: 13 }}>local_shipping</span></i><span>Đang vận chuyển<small>Dự kiến 21/09</small></span></div>
                <div><i><span className="material-symbols-outlined" style={{ fontSize: 13 }}>schedule</span></i><span>Giao thành công<small>Chờ cập nhật</small></span></div>
              </div>
              <div className="order-product-row-modern"><Image src="/assets/images/v7_1916.png" alt="Váy midi Sage Flow" width={70} height={92} /><div><strong>Váy midi Sage Flow</strong><span>Sage · M × 1</span></div><b>679.000₫</b></div>
              <div className="order-card-footer-modern"><span>Tổng thanh toán <strong>1.228.000₫</strong></span><button>Xem chi tiết</button></div>
            </article>}

            {(status === "Tất cả" || status === "Đã giao") && <article className="order-card-modern">
              <div className="order-card-modern-head"><div><small>ĐƠN HÀNG</small><strong>#ZEL88392</strong><span>10/09/2026 · 1 sản phẩm</span></div><div className="shipping-pill complete"><span className="material-symbols-outlined" style={{ fontSize: 15 }}>check</span> Đã giao</div></div>
              <div className="order-product-row-modern"><Image src="/assets/images/v7_1730.png" alt="Quần suông Soft Tailoring" width={70} height={92} /><div><strong>Quần suông Soft Tailoring</strong><span>Cocoa · S × 1</span></div><b>549.000₫</b></div>
              <div className="order-card-footer-modern"><span>Tổng thanh toán <strong>549.000₫</strong></span><div><Link href="/purchase-history">Đánh giá</Link><button>Mua lại</button></div></div>
            </article>}
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
