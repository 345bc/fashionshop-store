"use client";
import { useState, useEffect, use } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Image from "next/image";
import Link from "next/link";
import ProductAccordion from "@/components/ProductAccordion";
import ProductRail from "@/components/ProductRail";
import ProductSimilar from "@/components/ui/ProductSimilar";

import { getProductDetail } from "@/service/productService";
import type { PageResponse } from "@/type/api";

interface Review {
  id: number;
  customerName: string;
  rating: number;
  comment: string | null;
  colorName: string | null;
  sizeName: string | null;
  createdAt: string | null;
  adminReply: string | null;
  repliedAt: string | null;
}

const ratingStars = (rating: number) => {
  const stars = Math.max(0, Math.min(5, Math.round(rating)));
  return "★".repeat(stars) + "☆".repeat(5 - stars);
};

interface Product {
  id: number;
  name: string;
  slug: string;
  description: string;
  style: string;
  occasion: string;
  basePrice: number;
  categoryName: string;
  sizeGuideUrl: string;
  colors: { id: number; name: string; hexCode: string }[];
  sizes: { id: number; name: string }[];
  variants: {
    id: number;
    sku: string;
    colorId: number;
    sizeId: number;
    price: number;
    stockQuantity: number;
    images: { id: number; imageUrl: string; isPrimary: boolean; displayOrder: number }[];
  }[];
  averageRating: number;
  reviewsCount: number;
  reviews?: PageResponse<Review> | null;
}

export default function ProductDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const [selectedColorId, setSelectedColorId] = useState<number | null>(null);
  const [selectedSizeId, setSelectedSizeId] = useState<number | null>(null);
  const [selectedImageId, setSelectedImageId] = useState<number | null>(null);
  const [showSizeGuide, setShowSizeGuide] = useState(false);
  const [showCartPopup, setShowCartPopup] = useState(false);
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getProductDetail(id)
      .then((res) => {
        const data = res.data;
        setProduct(data);
        const firstVariant = data.variants?.[0];
        setSelectedColorId(firstVariant?.colorId ?? null);
        setSelectedSizeId(firstVariant?.sizeId ?? null);
        setSelectedImageId(null);
        setLoading(false);
      })
      .catch((err) => {
        console.error("Failed to fetch product:", err);
        setProduct(null);
        setLoading(false);
      });
  }, [id]);

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

  const selectedVariant = product.variants?.find(
    (v) => v.colorId === selectedColorId && v.sizeId === selectedSizeId
  );
  const colorVariants = product.variants?.filter((v) => v.colorId === selectedColorId) || [];

  const galleryImages = [...(selectedVariant?.images ?? [])].sort(
    (a, b) => Number(b.isPrimary) - Number(a.isPrimary)
      || a.displayOrder - b.displayOrder || a.id - b.id
  );
  const activeImage = galleryImages.find(image => image.id === selectedImageId) ?? galleryImages[0];
  const displayImage = activeImage?.imageUrl;

  const displayPrice = selectedVariant?.price || product.basePrice || 0;
  const formattedPrice = `${displayPrice.toLocaleString("vi-VN")} VNĐ`;
  const selectedColorObj = product.colors?.find(c => c.id === selectedColorId);
  const selectedSizeObj = product.sizes?.find(s => s.id === selectedSizeId);
  const canAddToCart = !!selectedVariant && selectedVariant.stockQuantity > 0;
  const reviews = product.reviews?.content ?? [];
  const hasReviews = reviews.length > 0;

  const selectColor = (colorId: number) => {
    const variants = product.variants?.filter(v => v.colorId === colorId) ?? [];
    const nextVariant = variants.find(v => v.sizeId === selectedSizeId) ?? variants[0];
    if (!nextVariant) return;
    setSelectedColorId(nextVariant.colorId);
    setSelectedSizeId(nextVariant.sizeId);
    setSelectedImageId(null);
  };

  return (
    <>
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 main-content" style={{ paddingBottom: 0 }}>

        {/* ── OUTER 3/5 + 2/5 LAYOUT ── */}
        <div className="product-page-layout" style={{ marginBottom: 0 }}>

          {/* LEFT COL – 3/5: gallery + description + reviews */}
          <div className="product-left-col">

            {/* Gallery */}
            <div className="gallery-container">
              <div className="gallery-thumbs" style={{ width: "clamp(84px, 10vw, 120px)" }}>
                {galleryImages.map((image, index) => (
                  <button
                    key={image.id}
                    type="button"
                    className={`thumb-item ${activeImage?.id === image.id ? "active" : ""}`}
                    aria-label={`Xem ảnh ${index + 1} của ${product.name}`}
                    aria-pressed={activeImage?.id === image.id}
                    onClick={() => setSelectedImageId(image.id)}
                    style={{ padding: 0, background: "transparent", flexShrink: 0 }}
                  >
                    <Image src={image.imageUrl} alt={`${product.name} - ảnh ${index + 1}`} width={120} height={160} style={{ objectFit: "contain" }} />
                  </button>
                ))}
              </div>

              <div className="gallery-main" style={{ aspectRatio: "4 / 5", alignSelf: "flex-start", minWidth: 0 }}>
                {displayImage ? <Image
                  src={displayImage}
                  alt={product.name}
                  width={700}
                  height={875}
                  style={{ width: "100%", height: "100%", objectFit: "contain" }}
                  priority
                /> : <div style={{ height: "100%", display: "grid", placeItems: "center", color: "var(--ink-secondary)" }}>Biến thể chưa có ảnh</div>}
              </div>
            </div>

            {/* ── DESCRIPTION ── */}
            <section className="product-description-section">
              <h2>Mô tả</h2>
              <p className="desc-subtitle">Mã sản phẩm: {selectedVariant ? selectedVariant.sku : product.id}</p>

              <div className="desc-accordions">
                <ProductAccordion title="Điểm nổi bật" defaultOpen={true}>
                  <p style={{ whiteSpace: 'pre-wrap' }}>{product.description}</p>
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
            {hasReviews && <section id="reviews" className="reviews-section">
              <div className="reviews-section-header">
                <div>
                  <p className="subtext">Phản hồi thực tế</p>
                  <h2>Đánh giá từ khách hàng</h2>
                </div>
                <div className="reviews-rating-summary">
                  <div className="rating-num">{product.averageRating.toFixed(1)}</div>
                  <div className="rating-stars">{ratingStars(product.averageRating)}</div>
                  <div className="rating-count">{product.reviewsCount} đánh giá</div>
                </div>
              </div>

              <div className="reviews-list">
                {reviews.map((r) => (
                  <div key={r.id} className="review-item">
                    <div className="review-header">
                      <div className="review-avatar">{r.customerName.charAt(0)}</div>
                      <div>
                        <div className="review-name">{r.customerName}</div>
                        <div className="review-meta">{[
                          r.createdAt ? new Date(r.createdAt).toLocaleDateString("vi-VN") : null,
                          r.sizeName ? `Size ${r.sizeName}` : null,
                          r.colorName,
                        ].filter(Boolean).join(" · ")}</div>
                      </div>
                      <div className="review-stars">
                        {ratingStars(r.rating)}
                      </div>
                    </div>
                    {r.comment && <p className="review-text">{r.comment}</p>}
                    {r.adminReply && <div className="review-text" style={{ marginTop: 12 }}>
                      <strong>Phản hồi từ ZELLA</strong>
                      <p>{r.adminReply}</p>
                    </div>}
                  </div>
                ))}
              </div>
            </section>}
          </div>

          {/* RIGHT COL – 2/5: sticky info panel */}
          <div className="product-right-col">
            <div className="detail-info detail-info-sticky">
              <h1 className="detail-title">{product.name}</h1>

              {/* Color */}
              <div className="detail-section">
                <div className="detail-section-label">
                  Màu sắc: <span>{selectedColorObj?.name}</span>
                </div>
                <div style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
                  {product.colors?.map((c) => {
                    const disabled = !product.variants?.some(v => v.colorId === c.id);
                    return (
                      <button
                        key={c.id}
                        type="button"
                        disabled={disabled}
                        aria-pressed={selectedColorId === c.id}
                        className={`color-swatch ${selectedColorId === c.id ? "active" : ""}`}
                        style={{ background: c.hexCode, opacity: disabled ? 0.3 : 1, cursor: disabled ? "not-allowed" : "pointer" }}
                        title={disabled ? `${c.name}: không có biến thể` : c.name}
                        onClick={() => selectColor(c.id)}
                      ></button>
                    );
                  })}
                </div>
              </div>

              {/* Size */}
              <div className="detail-section">
                <div className="detail-section-label">
                  Kích cỡ: <span>{selectedSizeObj?.name}</span>
                </div>
                <div className="size-btn-group" style={{ flexWrap: "wrap" }}>
                  {product.sizes?.map((sz) => {
                    const disabled = !colorVariants.some(v => v.sizeId === sz.id);
                    return (
                      <button
                        key={sz.id}
                        className={`size-btn ${selectedSizeId === sz.id ? "active" : ""}`}
                        type="button"
                        disabled={disabled}
                        aria-pressed={selectedSizeId === sz.id}
                        title={disabled ? `${sz.name}: không có cho màu đang chọn` : sz.name}
                        style={{ opacity: disabled ? 0.3 : 1, cursor: disabled ? "not-allowed" : "pointer", textDecoration: disabled ? "line-through" : "none" }}
                        onClick={() => { if (!disabled) { setSelectedSizeId(sz.id); setSelectedImageId(null); } }}
                      >
                        {sz.name}
                      </button>
                    );
                  })}
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
                {hasReviews && <div className="detail-rating-inline">
                  <span style={{ color: "#e8a000", letterSpacing: "2px" }}>{ratingStars(product.averageRating)}</span>
                  <span style={{ fontWeight: 600 }}>{product.averageRating.toFixed(1)}</span>
                  <Link href="#reviews" style={{ color: "var(--ink-secondary)", textDecoration: "none" }}>({product.reviewsCount})</Link>
                </div>}
              </div>

              {/* Cart */}
              <div className="detail-cart-row">
                <div className="qty-control">
                  <button type="button" className="qty-btn" style={{ color: "var(--ink-secondary)" }}>−</button>
                  <input type="text" defaultValue="1" readOnly className="qty-input" />
                  <button type="button" className="qty-btn" style={{ color: "var(--ink-primary)" }}>+</button>
                </div>
                <button type="button" disabled={!canAddToCart} onClick={() => { if (canAddToCart) setShowCartPopup(true); }} className="add-to-cart-btn"
                  style={{ opacity: canAddToCart ? 1 : 0.4, cursor: canAddToCart ? "pointer" : "not-allowed" }}>
                  THÊM VÀO GIỎ HÀNG
                </button>
              </div>

              <div className="detail-stock-note">
                {selectedVariant && selectedVariant.stockQuantity > 0
                  ? `Còn hàng (${selectedVariant.stockQuantity})`
                  : "Hết hàng"}
              </div>
            </div>
          </div>
        </div>{/* end product-page-layout */}
      </main>

      {/* ── SIMILAR PRODUCTS ── */}
      <ProductSimilar key={product.id} productId={product.id} />

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
              src={product.sizeGuideUrl || "/assets/images/v7_3803.png"}
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
                {displayImage && <Image src={displayImage} alt={product.name} width={300} height={400} style={{ width: "100%", height: "auto", objectFit: "contain", borderRadius: "8px" }} />}
              </div>
              <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center" }}>
                <h3 style={{ fontSize: "1.2rem", fontWeight: 400, marginBottom: "12px", letterSpacing: "0.5px" }}>{product.name}</h3>
                <div style={{ fontSize: "0.95rem", color: "#555", fontWeight: 300, display: "flex", flexDirection: "column", gap: "6px" }}>
                  <p><span style={{ color: "#999", display: "inline-block", width: "80px" }}>Màu sắc:</span> {selectedColorObj?.name}</p>
                  <p><span style={{ color: "#999", display: "inline-block", width: "80px" }}>Kích cỡ:</span> {selectedSizeObj?.name}</p>
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
