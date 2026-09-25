import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Link from "next/link";

export default function OrderSuccessPage() {
  return (
    <>
      <Header />
      <main className="order-success-modern">
        <section>
          <div className="success-mark"><span className="material-symbols-outlined" style={{ fontSize: 26 }}>check</span></div>
          <span className="eyebrow">ORDER CONFIRMED</span>
          <h1>Cảm ơn bạn.<br />Đơn hàng đã được ghi nhận.</h1>
          <p>Mã đơn hàng <strong>#ZEL91284</strong>. Zella sẽ cập nhật trạng thái xử lý và vận chuyển trong trang “Đơn hàng của tôi”.</p>
          <div className="success-order-note"><span className="material-symbols-outlined" style={{ fontSize: 19 }}>inventory</span><div><strong>Đang chờ xử lý</strong><span>Dự kiến giao trong 2–4 ngày làm việc</span></div></div>
          <div className="success-actions"><Link href="/orders" className="modern-btn dark">Theo dõi đơn hàng</Link><Link href="/products" className="modern-btn light">Tiếp tục mua sắm</Link></div>
        </section>
      </main>
      <Footer />
    </>
  );
}
