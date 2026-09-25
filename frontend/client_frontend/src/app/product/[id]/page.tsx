"use client";
import { useState, useEffect, use } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Image from "next/image";
import Link from "next/link";
import ProductAccordion from "@/components/ProductAccordion";
import ProductRail from "@/components/ProductRail";

interface Product {
  id: number;
  title: string;
  price: number;
  description: string;
  category: string;
  image: string;
  rating?: {
    rate: number;
    count: number;
  };
  [key: string]: unknown;
}

export default function ProductDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [selectedColor, setSelectedColor] = useState(0);
  const [selectedSize, setSelectedSize] = useState("M");
  const [showSizeGuide, setShowSizeGuide] = useState(false);
  const [showCartPopup, setShowCartPopup] = useState(false);
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`https://fakestoreapi.com/products/${id}`)
      .then(async (res) => {
        if (!res.ok) throw new Error("Product not found");
        const text = await res.text();
        return text ? JSON.parse(text) : null;
      })
      .then((data) => {
        setProduct(data);
        setLoading(false);
      })
      .catch((err) => {
        console.error("Failed to fetch product:", err);
        setProduct(null);
        setLoading(false);
      });
  }, [id]);

  const colors = [
    { name: "60 LIGHT BLUE", hex: "#c2d6e6" },
    { name: "03 LIGHT GRAY", hex: "#e5e5e5" },
    { name: "09 BLACK", hex: "#111111" },
  ];

  if (loading) {
    return (
      <>
        <Header />
        <main className="main-content" style={{ padding: "100px", textAlign: "center" }}>Đang tải...</main>
        <Footer />
      </>
    );
  }

  if (!product) {
    return (
      <>
        <Header />
        <main className="main-content" style={{ padding: "100px", textAlign: "center" }}>Sản phẩm không tồn tại</main>
        <Footer />
      </>
    );
  }

  const formattedPrice = `${(product.price * 25000).toLocaleString('vi-VN')} VND`;

  return (
    <>
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 main-content">


        {/* ── OUTER 3/5 + 2/5 LAYOUT ── */}
        <div className="product-page-layout">

          {/* LEFT COL – 3/5: gallery + description + reviews */}
          <div className="product-left-col">

            {/* Gallery */}
            <div className="gallery-container">
              <div className="gallery-thumbs">
                <div className="thumb-item active">
                  <Image src={product.image} alt="góc chính" width={100} height={130} style={{ objectFit: 'contain' }} />
                </div>
              </div>

              <div className="gallery-main">
                <Image
                  src={product.image}
                  alt={product.title}
                  width={700}
                  height={933}
                  style={{ width: "100%", height: "auto", objectFit: "contain" }}
                  priority
                />
              </div>
            </div>

            {/* ── DESCRIPTION ── */}
            <section className="product-description-section">
              <h2>Mô tả</h2>
              <p className="desc-subtitle">Mã sản phẩm: {product.id}</p>

              <div className="desc-accordions">
                <ProductAccordion title="Điểm nổi bật" defaultOpen={true}>
                  <p>{product.description}</p>
                </ProductAccordion>
                <ProductAccordion title="Chi Tiết">
                  <p>- Có túi kangaroo phía trước.</p>
                  <p>- Mũ trùm đầu rộng rãi.</p>
                  <p>- Bo viền cổ tay và vạt áo chắc chắn.</p>
                </ProductAccordion>
                <ProductAccordion title="Chất liệu / Cách chăm sóc">
                  <p>- 75% Cotton, 25% Polyester.</p>
                  <p>- Giặt máy nước lạnh, chế độ nhẹ nhàng.</p>
                  <p>- Không sử dụng thuốc tẩy.</p>
                </ProductAccordion>
                <ProductAccordion title="Giao Hàng / Đổi / Trả Hàng">
                  <p>- Miễn phí giao hàng cho đơn từ 1.500.000 VNĐ.</p>
                  <p>- Thời gian giao hàng: 2–4 ngày làm việc.</p>
                  <p>- Đổi trả linh hoạt trong vòng 14 ngày.</p>
                </ProductAccordion>
                <ProductAccordion title="Sản xuất">
                  <p>- Xuất xứ: Việt Nam / Bangladesh / Indonesia.</p>
                </ProductAccordion>
              </div>
            </section>

            {/* ── REVIEWS – vertical list ── */}
            <section id="reviews" className="reviews-section">
              <div className="reviews-section-header">
                <div>
                  <p className="subtext">Phản hồi thực tế</p>
                  <h2>Đánh giá từ khách hàng</h2>
                </div>
                <div className="reviews-rating-summary">
                  <div className="rating-num">{product.rating?.rate || "5.0"}</div>
                  <div className="rating-stars">★★★★★</div>
                  <div className="rating-count">{product.rating?.count || "0"} đánh giá</div>
                </div>
              </div>

              <div className="reviews-list">
                {[
                  { name: "Mai Anh", rating: 5, date: "12/09/2026", size: "M", text: "Form váy rất đẹp, vải mát và màu giống hình chụp. Mặc đi làm ai cũng khen phong cách thanh lịch, rất hài lòng với Zella!" },
                  { name: "Thu Hà", rating: 5, date: "08/09/2026", size: "S", text: "Đóng gói rất chỉn chu và thơm mùi hoa cỏ nhẹ nhàng. Mình cao 1m60 nặng 52kg chọn size M vừa vặn y như may đo." },
                  { name: "Ngọc Linh", rating: 4, date: "05/09/2026", size: "L", text: "Thiết kế tối giản nhưng đường may rất sắc nét. Mặc đi dạo phố hay du lịch chụp ảnh rất thơ và thanh thoát." },
                ].map((r) => (
                  <div key={r.name} className="review-item">
                    <div className="review-header">
                      <div className="review-avatar">{r.name.charAt(0)}</div>
                      <div>
                        <div className="review-name">{r.name}</div>
                        <div className="review-meta">{r.date} · Size {r.size}</div>
                      </div>
                      <div className="review-stars">
                        {"★".repeat(r.rating)}{"☆".repeat(5 - r.rating)}
                      </div>
                    </div>
                    <p className="review-text">{r.text}</p>
                  </div>
                ))}
              </div>
            </section>
          </div>

          {/* RIGHT COL – 2/5: sticky info panel */}
          <div className="product-right-col">
            <div className="detail-info detail-info-sticky">
              <h1 className="detail-title">{product.title}</h1>

              {/* Color */}
              <div className="detail-section">
                <div className="detail-section-label">
                  Màu sắc: <span>{colors[selectedColor].name}</span>
                </div>
                <div style={{ display: "flex", gap: "10px" }}>
                  {colors.map((c, idx) => (
                    <button
                      key={idx}
                      className={`color-swatch ${selectedColor === idx ? "active" : ""}`}
                      style={{ background: c.hex }}
                      title={c.name}
                      onClick={() => setSelectedColor(idx)}
                    ></button>
                  ))}
                </div>
              </div>

              {/* Size */}
              <div className="detail-section">
                <div className="detail-section-label">
                  Kích cỡ: <span>Nam {selectedSize}</span>
                </div>
                <div className="size-btn-group">
                  {["S", "M", "L", "XL"].map((sz) => (
                    <button
                      key={sz}
                      className={`size-btn ${selectedSize === sz ? "active" : ""}`}
                      type="button"
                      onClick={() => setSelectedSize(sz)}
                    >
                      {sz}
                    </button>
                  ))}
                </div>
                <div className="size-guide-link">
                  <button type="button" onClick={() => setShowSizeGuide(true)} className="size-guide-btn">
                    <span className="material-symbols-outlined" style={{ fontSize: 18 }}>straighten</span>
                    Kích cỡ
                  </button>
                </div>
              </div>

              {/* Price + Rating */}
              <div className="detail-price-row">
                <div className="detail-price">{formattedPrice}</div>
                <div className="detail-rating-inline">
                  <span style={{ color: "#e8a000", letterSpacing: "2px" }}>★★★★★</span>
                  <span style={{ fontWeight: 600 }}>{product.rating?.rate || "5.0"}</span>
                  <Link href="#reviews" style={{ color: "var(--ink-secondary)", textDecoration: "none" }}>({product.rating?.count || "0"})</Link>
                </div>
              </div>

              {/* Cart */}
              <div className="detail-cart-row">
                <div className="qty-control">
                  <button type="button" className="qty-btn" style={{ color: "var(--ink-secondary)" }}>−</button>
                  <input type="text" defaultValue="1" readOnly className="qty-input" />
                  <button type="button" className="qty-btn" style={{ color: "var(--ink-primary)" }}>+</button>
                </div>
                <button type="button" onClick={() => setShowCartPopup(true)} className="add-to-cart-btn">
                  THÊM VÀO GIỎ HÀNG
                </button>
              </div>

              <div className="detail-stock-note">Còn hàng</div>
            </div>
          </div>
        </div>{/* end product-page-layout */}
      </main>

      {/* ── SIMILAR PRODUCTS ── */}
      <div className="product-related-rails" style={{ marginTop: 64 }}>
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="slider-section-title" style={{ marginBottom: 12, fontSize: "1.5rem" }}>Sản phẩm tương tự</h2>
        </div>
        <ProductRail
          products={[
            { id: "1", name: "Áo Thun Kẻ Ngang", price: "299.000₫", image: "/assets/images/v7_1909.png", badge: "Hàng bán chạy", rating: 4.8, reviewsCount: 24 },
            { id: "2", name: "Áo Thun Màu Vàng", price: "299.000₫", image: "/assets/images/v7_1916.png", badge: "Hàng bán chạy", rating: 4.9, reviewsCount: 128 },
            { id: "3", name: "Áo Thun Kẻ Ngang Trắng Xanh", price: "299.000₫", image: "/assets/images/v7_1923.png", rating: 4.8, reviewsCount: 45 },
            { id: "4", name: "Áo Thun Cổ Cảm Hứng Đi Phượt", price: "299.000₫", image: "/assets/images/v7_1930.png", rating: 4.7, reviewsCount: 30 },
            { id: "5", name: "Áo Thun Basic Trắng", price: "249.000₫", image: "/assets/images/v7_1909.png", rating: 4.6, reviewsCount: 88 },
          ]}
        />
      </div>

      {/* ── FREQUENTLY BOUGHT TOGETHER ── */}
      <div className="product-related-rails" style={{ marginTop: 64, marginBottom: 80 }}>
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          <h2 className="slider-section-title" style={{ marginBottom: 12, fontSize: "1.5rem" }}>Thường được mua kèm</h2>
        </div>
        <ProductRail
          products={[
            { id: "6", name: "Quần Jogger Cotton", price: "399.000₫", image: "/assets/images/v7_1916.png", rating: 4.7, reviewsCount: 52 },
            { id: "7", name: "Áo Thun Unisex", price: "279.000₫", image: "/assets/images/v7_1923.png", badge: "Mới", rating: 4.5, reviewsCount: 19 },
            { id: "8", name: "Áo Khoác Gió Nhẹ", price: "499.000₫", image: "/assets/images/v7_1930.png", rating: 4.8, reviewsCount: 67 },
            { id: "9", name: "Quần Short Thể Thao", price: "329.000₫", image: "/assets/images/v7_1909.png", rating: 4.4, reviewsCount: 33 },
          ]}
        />
      </div>
      <Footer />

      {/* Size Guide Modal */}
      {showSizeGuide && (
        <div
          style={{ position: "fixed", top: 0, left: 0, width: "100%", height: "100%", backgroundColor: "rgba(0,0,0,0.85)", zIndex: 9999, display: "flex", justifyContent: "center", alignItems: "center" }}
          onClick={() => setShowSizeGuide(false)}
        >
          <div style={{ position: "relative", width: "90%", maxWidth: "600px" }} onClick={(e) => e.stopPropagation()}>
            <button
              style={{ position: "absolute", top: "-40px", right: "0", background: "none", border: "none", color: "#fff", fontSize: "2rem", cursor: "pointer" }}
              onClick={() => setShowSizeGuide(false)}
            >
              &times;
            </button>
            <Image
              src="/assets/images/v7_3803.png"
              alt="Bảng Kích Cỡ"
              width={600}
              height={800}
              style={{ width: "100%", height: "auto", objectFit: "contain", maxHeight: "90vh", borderRadius: "8px" }}
            />
          </div>
        </div>
      )}

      {/* Add to Cart Popup */}
      {showCartPopup && (
        <div
          style={{ position: "fixed", top: 0, left: 0, width: "100%", height: "100%", backgroundColor: "rgba(0,0,0,0.4)", backdropFilter: "blur(4px)", zIndex: 10000, display: "flex", justifyContent: "center", alignItems: "center" }}
          onClick={() => setShowCartPopup(false)}
        >
          <div style={{ backgroundColor: "#fff", width: "90%", maxWidth: "800px", padding: "48px", position: "relative", boxShadow: "0 20px 40px rgba(0,0,0,0.1)", borderRadius: "12px" }} onClick={(e) => e.stopPropagation()}>
            <button
              style={{ position: "absolute", top: "24px", right: "24px", background: "none", border: "none", cursor: "pointer", color: "#111", display: "flex", alignItems: "center", justifyContent: "center" }}
              onClick={() => setShowCartPopup(false)}
            >
              <span className="material-symbols-outlined" style={{ fontSize: 24 }}>close</span>
            </button>
            <h2 style={{ fontSize: "1.2rem", fontWeight: 300, marginBottom: "8px", textTransform: "uppercase", letterSpacing: "1px" }}>Thêm vào giỏ hàng thành công</h2>

            <p style={{ fontWeight: 400, fontSize: "1rem", color: "#333", marginBottom: "4px" }}>Tổng số tiền (1 sản phẩm): <span style={{ fontWeight: 500 }}>{formattedPrice}</span></p>
            <p style={{ fontSize: "0.85rem", color: "#777", marginBottom: "32px", fontWeight: 300 }}>Đơn hàng của bạn đủ điều kiện áp dụng miễn phí vận chuyển.</p>

            {/* Added Product Info */}
            <div style={{ borderTop: "1px solid #eaeaea", borderBottom: "1px solid #eaeaea", padding: "32px 0", display: "flex", gap: "32px", marginBottom: "40px" }}>
              <div style={{ width: "160px", flexShrink: 0 }}>
                <Image src={product.image} alt={product.title} width={300} height={400} style={{ width: "100%", height: "auto", objectFit: "contain", borderRadius: "8px" }} />
              </div>
              <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center" }}>
                <h3 style={{ fontSize: "1.2rem", fontWeight: 400, marginBottom: "12px", letterSpacing: "0.5px" }}>{product.title}</h3>
                <div style={{ fontSize: "0.95rem", color: "#555", fontWeight: 300, display: "flex", flexDirection: "column", gap: "6px" }}>
                  <p><span style={{ color: "#999", display: "inline-block", width: "80px" }}>Màu sắc:</span> {colors[selectedColor].name}</p>
                  <p><span style={{ color: "#999", display: "inline-block", width: "80px" }}>Kích cỡ:</span> Nam {selectedSize}</p>
                  <p><span style={{ color: "#999", display: "inline-block", width: "80px" }}>Số lượng:</span> 1</p>
                </div>
                <p style={{ fontSize: "1.2rem", fontWeight: 500, marginTop: "24px" }}>{formattedPrice}</p>
              </div>
            </div>

            {/* Actions */}
            <div style={{ display: "flex", gap: "20px" }}>
              <Link href="/cart" style={{ flex: 1, padding: "16px", backgroundColor: "#000", color: "#fff", border: "1px solid #000", fontWeight: 400, fontSize: "0.9rem", letterSpacing: "1px", textTransform: "uppercase", cursor: "pointer", transition: "all 0.3s", display: "flex", justifyContent: "center", alignItems: "center", textDecoration: "none" }}>
                Xem giỏ hàng
              </Link>
              <button style={{ flex: 1, padding: "16px", backgroundColor: "#fff", color: "#000", border: "1px solid #ccc", fontWeight: 400, fontSize: "0.9rem", letterSpacing: "1px", textTransform: "uppercase", cursor: "pointer", transition: "all 0.3s" }} onClick={() => setShowCartPopup(false)}>
                Tiếp tục mua sắm
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
