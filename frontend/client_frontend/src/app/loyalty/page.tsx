import Header from "@/components/Header";
import Footer from "@/components/Footer";
import AccountNav from "@/components/AccountNav";
import Link from "next/link";

export default function LoyaltyPage() {
  return (
    <>
      <Header />
      <main className="main-content modern-main account-modern-page">
        <div className="breadcrumb modern-breadcrumb"><Link href="/">Trang chủ</Link><span>/</span><span>Điểm thưởng</span></div>
        <div className="account-modern-layout">
          <AccountNav active="loyalty" />
          <section className="account-content-modern">
            <span className="eyebrow">ZELLA REWARDS</span><h1>Điểm thưởng</h1><p className="account-lead">Tích điểm từ các đơn hoàn tất và sử dụng cho những ưu đãi tiếp theo.</p>
            <div className="loyalty-hero-modern"><div><small>SỐ DƯ HIỆN TẠI</small><strong>1,250</strong><span>điểm Zella</span></div><div><span className="material-symbols-outlined" style={{ fontSize: 22 }}>auto_awesome</span><p>Bạn còn <strong>750 điểm</strong> để lên hạng Vàng.</p><div className="loyalty-progress"><i style={{ width: "62%" }} /></div></div></div>
            <div className="loyalty-grid-modern"><div><span className="material-symbols-outlined" style={{ fontSize: 21 }}>redeem</span><strong>Đổi voucher 100.000₫</strong><span>Cần 1.000 điểm</span><button>Đổi ngay <span className="material-symbols-outlined" style={{ fontSize: 14 }}>north_east</span></button></div><div><span className="material-symbols-outlined" style={{ fontSize: 21 }}>redeem</span><strong>Miễn phí vận chuyển</strong><span>Cần 500 điểm</span><button>Đổi ngay <span className="material-symbols-outlined" style={{ fontSize: 14 }}>north_east</span></button></div></div>
            <div className="points-history-modern"><h2>Lịch sử điểm</h2><div><span><strong>+136 điểm</strong><small>Đơn #ZEL88392 hoàn tất</small></span><time>10/09/2026</time></div><div><span><strong>-500 điểm</strong><small>Đổi ưu đãi miễn phí vận chuyển</small></span><time>02/09/2026</time></div><div><span><strong>+110 điểm</strong><small>Đơn #ZEL86704 hoàn tất</small></span><time>22/08/2026</time></div></div>
          </section>
        </div>
      </main>
      <Footer />
    </>
  );
}
