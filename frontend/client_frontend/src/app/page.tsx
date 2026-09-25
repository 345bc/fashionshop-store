import Header from "@/components/Header";
import Footer from "@/components/Footer";
import ProductRail from "@/components/ProductRail";
import Image from "next/image";
import Link from "next/link";

const featured = [
  { id: "1", name: "Áo sơ mi Relaxed Linen", price: "429.000₫", image: "/assets/images/aosomi-removebg-preview.png", badge: "Mới", rating: 4.9, reviewsCount: 42 },
  { id: "2", name: "Quần suông Soft Tailoring", price: "549.000₫", image: "/assets/images/pin_2814818513194861__p1-removebg-preview.png", rating: 4.8, reviewsCount: 61 },
  { id: "3", name: "Váy midi Sage Flow", price: "679.000₫", image: "/assets/images/pin_710794753734896504-removebg-preview.png", badge: "Best seller", rating: 4.9, reviewsCount: 128 },
  { id: "4", name: "Set vest Modern Balance", price: "899.000₫", image: "/assets/images/pin_64880050874016148-removebg-preview (1).png", rating: 4.8, reviewsCount: 30 },
  { id: "5", name: "Đầm satin Sand Drape", price: "729.000₫", image: "/assets/images/v7_1937.png", badge: "Limited", rating: 4.7, reviewsCount: 34 },
  { id: "6", name: "Quần ống rộng Cocoa", price: "489.000₫", image: "/assets/images/v7_1923.png", rating: 4.8, reviewsCount: 57 },
  { id: "7", name: "Áo dệt kim Ivory Air", price: "299.000₫", image: "/assets/images/v7_2123.png", rating: 4.6, reviewsCount: 23 },
  { id: "8", name: "Túi cói Studio Basket", price: "359.000₫", image: "/assets/images/v7_1944.png", badge: "Mới", rating: 4.9, reviewsCount: 49 },
];

const newArrivals = [
  { id: "9", name: "Váy midi Olive Line", price: "619.000₫", image: "/assets/images/v7_2020.png", badge: "Mới", rating: 4.8, reviewsCount: 75 },
  { id: "10", name: "Áo dài tay Minimal Knit", price: "329.000₫", image: "/assets/images/v7_1909.png", badge: "Mới", rating: 4.7, reviewsCount: 18 },
  { id: "11", name: "Chân váy Sage Pleat", price: "459.000₫", image: "/assets/images/v7_2019.png", badge: "Mới", rating: 4.9, reviewsCount: 66 },
  { id: "12", name: "Blazer Taupe Structure", price: "799.000₫", image: "/assets/images/v7_1713.png", badge: "Mới", rating: 4.8, reviewsCount: 39 },
  { id: "13", name: "Áo kiểu Soft Cream", price: "389.000₫", image: "/assets/images/v7_1930.png", rating: 4.8, reviewsCount: 26 },
  { id: "14", name: "Set dệt kim Quiet Ivory", price: "759.000₫", image: "/assets/images/v7_3793.png", rating: 4.9, reviewsCount: 31 },
  { id: "15", name: "Đầm linen Morning Sage", price: "689.000₫", image: "/assets/images/v7_3783.png", rating: 4.7, reviewsCount: 22 },
  { id: "16", name: "Quần linen Cinnamon", price: "529.000₫", image: "/assets/images/v7_3788.png", rating: 4.8, reviewsCount: 41 },
];

export default function Home() {
  return (
    <>
      <Header />
      <main className="home-redesign">
        <div className="modern-container">
          <section className="modern-hero" style={{ height: "calc(100vh - 100px)", minHeight: "unset" }}>
            <div className="modern-hero-copy">
              <span className="eyebrow">AUTUMN / 2026</span>
              <h1>Quiet forms.<br />Strong presence.</h1>
              <p>Một tủ đồ hiện đại không cần quá nhiều. Chỉ cần phom dáng đẹp, màu sắc dễ phối và những món bạn muốn mặc lại nhiều lần.</p>
              <div className="hero-actions">
                <Link href="/products" className="modern-btn dark">Khám phá bộ sưu tập</Link>
                <Link href="/products?cat=new" className="modern-text-link">Xem sản phẩm mới <span>↗</span></Link>
              </div>
              <div className="hero-notes">
                <span>01 / Natural palette</span><span>02 / Easy tailoring</span><span>03 / Everyday pieces</span>
              </div>
            </div>
            <div className="modern-hero-visual">
              <video autoPlay muted loop playsInline preload="metadata" poster="/assets/images/v7_1705.png" aria-label="Zella Autumn 2026 fashion film">
                <source src="/assets/videos/zella-hero-main.mp4" type="video/mp4" />
              </video>
              <div className="hero-floating-card">
                <span>THE NEW EDIT</span>
                <strong>Warm neutrals</strong>
                <Link href="/products">Shop now →</Link>
              </div>
            </div>
          </section>

          <section className="home-section category-edit-section">
            <div className="section-heading-modern">
              <div><span className="eyebrow">SHOP BY EDIT</span><h2>Chọn theo phong cách</h2></div>
              <Link href="/products">Xem tất cả →</Link>
            </div>
            <div className="modern-category-grid">
              <Link href="/products?cat=nu-ao" className="modern-category-card large">
                <Image src="/assets/images/v7_1758.png" alt="Essential shirts" fill sizes="50vw" />
                <div><small>THE ESSENTIALS</small><strong>Soft shirts</strong><span>Khám phá →</span></div>
              </Link>
              <Link href="/products?cat=nu-vay" className="modern-category-card">
                <Image src="/assets/images/v7_1735.png" alt="Flowing dresses" fill sizes="25vw" />
                <div><small>FEMININE LINE</small><strong>Flowing dresses</strong><span>Khám phá →</span></div>
              </Link>
              <Link href="/products?cat=nu-quan" className="modern-category-card">
                <Image src="/assets/images/v7_1730.png" alt="Tailored pants" fill sizes="25vw" />
                <div><small>MODERN WORKWEAR</small><strong>Tailored pants</strong><span>Khám phá →</span></div>
              </Link>
            </div>
          </section>
        </div>

        <section className="campaign-fullwidth" aria-label="Bộ sưu tập Coastal Linen">
          <Link href="/products?cat=linen" className="campaign-panel-full">
            <Image src="/assets/images/imagess.png" alt="Bộ sưu tập linen bên bờ biển" fill sizes="100vw" />
            <div><span>COASTAL Linen</span><strong>Nhẹ tênh trong từng chuyển động</strong><small>Khám phá bộ sưu tập →</small></div>
          </Link>
        </section>

        <ProductRail products={featured} href="/products" />

        <section className="campaign-fullwidth" aria-label="Bộ sưu tập Soft Tailoring">
          <Link href="/products?cat=soft-tailoring" className="campaign-panel-full">
            <Image src="/assets/images/v7_3590.png" alt="Bộ sưu tập Soft Tailoring" fill sizes="100vw" />
            <div><span>SOFT TAILORING</span><strong>Phom dáng mềm, hiện diện rõ</strong><small>Xem thiết kế mới →</small></div>
          </Link>
        </section>

        <ProductRail products={newArrivals} href="/products?cat=new" />

        <div className="modern-container">

          <section className="editorial-banner" style={{ marginBottom: 60 }}>
            <div className="editorial-image"><Image src="/assets/images/v7_1795.png" alt="Zella editorial" fill sizes="50vw" /></div>
            <div className="editorial-copy">
              <span className="eyebrow">ZELLA JOURNAL / 04</span>
              <h2>Mặc ít hơn,<br />phối thông minh hơn.</h2>
              <p>5 công thức phối đồ trung tính giúp bạn đi từ văn phòng đến buổi hẹn tối mà không cần thay cả set.</p>
              <Link href="/blog" className="modern-text-link">Đọc journal <span>↗</span></Link>
            </div>
          </section>


        </div>
      </main>
      <Footer />
    </>
  );
}
