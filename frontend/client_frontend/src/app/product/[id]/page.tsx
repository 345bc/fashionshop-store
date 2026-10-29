"use client";

import GoogleSymbol from "@/components/ui/GoogleSymbol";

import ProductReviews from "@/components/product/ProductReviews";
import MaterialAndCareSample from "@/components/product/MaterialAndCareSample";
import DeliveryAndReturnsSample from "@/components/product/DeliveryAndReturnsSample";
import { useState, useEffect, useRef, use } from "react";
import galleryStyles from "./ProductGallery.module.css";
import Header from "@/components/Header";
import { useCart } from "@/cart/CartContext";
import { money } from "@/cart/types";
import Footer from "@/components/Footer";
import Image from "next/image";
import ProductAccordion from "@/components/ProductAccordion";
import ProductBoughtTogether from "@/components/ui/ProductBoughtTogether";
import ProductSimilar from "@/components/ui/ProductSimilar";

import ProductDetailSkeleton from "@/components/skeleton-ui/ProductDetailSkeleton";
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


interface Product {
  id: number;
  name: string;
  slug: string;
  description: string;
  style: string;
  occasion: string;
  basePrice: number;
  salePrice: number | null;
  discountPercent: number | null;
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
    salePrice: number | null;
    stockQuantity: number;
    images: { id: number; imageUrl: string; isPrimary: boolean; displayOrder: number }[];
  }[];
  averageRating: number;
  reviewsCount: number;
  reviews?: PageResponse<Review> | null;
}

export default function ProductDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const cart = useCart();
  const [quantity, setQuantity] = useState(1);
  const [adding, setAdding] = useState(false);
  const [cartError, setCartError] = useState("");
  const [selectedColorId, setSelectedColorId] = useState<number | null>(null);
  const [selectedSizeId, setSelectedSizeId] = useState<number | null>(null);
  const [selectedImageId, setSelectedImageId] = useState<number | null>(null);
  const [imageDirection, setImageDirection] = useState<"next" | "previous">("next");
  const [showSizeGuide, setShowSizeGuide] = useState(false);
  const [showCartPopup, setShowCartPopup] = useState(false);
  const [product, setProduct] = useState<Product | null>(null);
  const [loading, setLoading] = useState(true);
  const thumbnailTrack = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const track = thumbnailTrack.current;
    if (!track) return;
    const revealSelectedThumbnail = () => {
      const selected = track.querySelector<HTMLButtonElement>('[aria-pressed="true"]');
      if (!selected || track.clientHeight === 0) return;
      const horizontal = track.scrollWidth > track.clientWidth;
      const top = horizontal ? selected.offsetLeft : selected.offsetTop;
      const bottom = top + (horizontal ? selected.offsetWidth : selected.offsetHeight);
      const visibleTop = horizontal ? track.scrollLeft : track.scrollTop;
      const extent = horizontal ? track.clientWidth : track.clientHeight;
      const visibleBottom = visibleTop + extent;
      const target = top < visibleTop ? top : bottom > visibleBottom ? bottom - extent : null;
      if (target !== null) track.scrollTo({
        ...(horizontal ? { left: target } : { top: target }),
        behavior: window.matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth",
      });
    };
    revealSelectedThumbnail();
    const observer = new ResizeObserver(revealSelectedThumbnail);
    observer.observe(track);
    return () => observer.disconnect();
  }, [loading, product, selectedImageId, selectedColorId, selectedSizeId]);

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
        <ProductDetailSkeleton />
        <Footer />
      </>
    );
  }

  if (!product) {
    return (
      <>
        <Header />
        <main className="container mx-auto px-3 sm:px-4 main-content" style={{ padding: "100px 0", textAlign: "center" }}>
          <p style={{ color: "var(--ink-secondary)", fontSize: "16px" }}>Sản phẩm không tồn tại hoặc đã ngừng kinh doanh.</p>
        </main>
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

  const currentPrice = selectedVariant?.price ?? product.basePrice ?? 0;
  const currentSalePrice = selectedVariant?.salePrice ?? product.salePrice ?? null;
  const displayPrice = currentSalePrice ?? currentPrice;
  const originalPrice = currentSalePrice ? currentPrice : null;

  const formattedPrice = `${displayPrice.toLocaleString("vi-VN")} VND`;
  const formattedOriginalPrice = originalPrice ? `${originalPrice.toLocaleString("vi-VN")} VND` : null;
  const discountBadge = product.discountPercent ? `-${product.discountPercent}%` : null;

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
    setQuantity(1);
  };

  const activeIndex = galleryImages.findIndex(img => img.id === activeImage?.id);
  const handlePrevImage = () => {
    if (galleryImages.length <= 1) return;
    setImageDirection("previous");
    const newIdx = activeIndex > 0 ? activeIndex - 1 : galleryImages.length - 1;
    setSelectedImageId(galleryImages[newIdx].id);
  };
  const handleNextImage = () => {
    if (galleryImages.length <= 1) return;
    setImageDirection("next");
    const newIdx = activeIndex < galleryImages.length - 1 ? activeIndex + 1 : 0;
    setSelectedImageId(galleryImages[newIdx].id);
  };

  return (
    <>
      <Header />
      <main className={`main-content ${galleryStyles.page}`}>

        {/* Gallery, purchase panel, then product details on small screens. */}
        <div className={`product-page-layout ${galleryStyles.layout}`} style={{ marginBottom: 0 }}>


          <div data-direction={imageDirection} className={`${galleryStyles.stage} ${galleryImages.length < 2 ? galleryStyles.singleImage : ''}`}>
            {displayImage ? <>
              <div className={galleryStyles.imagePanel}>
                <Image key={displayImage} src={displayImage} alt={product.name} fill priority
                  sizes="(max-width: 600px) 100vw, (max-width: 900px) 50vw, 36vw" />
              </div>
              {galleryImages.length > 1 && <div className={`${galleryStyles.imagePanel} ${galleryStyles.secondImage}`}>
                <Image key={galleryImages[(activeIndex + 1) % galleryImages.length].id} src={galleryImages[(activeIndex + 1) % galleryImages.length].imageUrl}
                  alt={`${product.name} - góc nhìn tiếp theo`} fill
                  sizes="(max-width: 900px) 50vw, 36vw" />
              </div>}
              {galleryImages.length > 1 && <>
                <button type="button" className={`${galleryStyles.imageArrow} ${galleryStyles.previousImage}`}
                  onClick={handlePrevImage} aria-label="Ảnh trước"><GoogleSymbol name="chevron_left" size={30} /></button>
                <button type="button" className={`${galleryStyles.imageArrow} ${galleryStyles.nextImage}`}
                  onClick={handleNextImage} aria-label="Ảnh tiếp theo"><GoogleSymbol name="chevron_right" size={30} /></button>
                <span className={galleryStyles.imageCounter}>{activeIndex + 1} / {galleryImages.length}</span>
              </>}
            </> : <div className={galleryStyles.emptyImage}>Biến thể chưa có ảnh</div>}
          </div>

          {/* RIGHT COL – 2/5: sticky info panel */}
          <div className="product-right-col">
            <div className="detail-info detail-info-sticky">
              <div className={galleryStyles.thumbnailStrip}>
                <div ref={thumbnailTrack} className={galleryStyles.stripTrack} aria-label="Danh sách ảnh sản phẩm">
                  {galleryImages.map((image, index) => (
                    <button
                      key={image.id}
                      type="button"
                      className={`thumb-item ${activeImage?.id === image.id ? "active" : ""}`}
                      aria-label={`Xem ảnh ${index + 1} của ${product.name}`}
                      aria-pressed={activeImage?.id === image.id}
                      onClick={() => setSelectedImageId(image.id)}

                    >
                      <Image src={image.imageUrl} alt={`${product.name} - ảnh ${index + 1}`} width={120} height={160} style={{ objectFit: "contain" }} />
                    </button>
                  ))}
                </div>
              </div>
              <div className="detail-heading">
                <p className="detail-brand">ZELLA</p>
                <h1 className="detail-title">{product.name.normalize("NFC")}</h1>
              </div>

              {/* Price + Rating */}
              <div className="detail-price-row">
                <div className="detail-price" style={{ display: 'flex', gap: '12px', alignItems: 'center', flexWrap: 'wrap' }}>
                  <span style={{ color: formattedOriginalPrice ? 'red' : 'inherit' }}>{formattedPrice}</span>
                  {formattedOriginalPrice && (
                    <span style={{ textDecoration: 'line-through', color: '#888', fontWeight: 'normal', fontSize: '0.65em' }}>{formattedOriginalPrice}</span>
                  )}
                  {discountBadge && (
                    <span style={{ background: '#e00', color: 'white', fontSize: '0.55em', padding: '2px 8px', borderRadius: '4px', fontWeight: 'bold' }}>{discountBadge}</span>
                  )}
                </div>
              </div>

              {/* Color */}
              <div className="detail-section detail-color-section">
                <div className={galleryStyles.colorHeading}>
                <div className="detail-section-label">
                  Màu sắc: <span>{selectedColorObj?.name}</span>
                </div>

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
                <div className={galleryStyles.colorHeading}>
                <div className="detail-section-label">
                  Kích cỡ: <span>{selectedSizeObj?.name}</span>
                </div>
                <div className={galleryStyles.inlineSizeGuide}>
                  <button type="button" onClick={() => setShowSizeGuide(true)} className="size-guide-btn">
                    <span className="material-symbols-outlined" style={{ fontSize: 18 }}>straighten</span>
                    Kích cỡ
                  </button>
                </div>
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
                        onClick={() => { if (!disabled) { setSelectedSizeId(sz.id); setSelectedImageId(null); setQuantity(1); } }}
                      >
                        {sz.name}
                      </button>
                    );
                  })}
                </div>

              </div>

              {/* Cart */}
              <div className="detail-cart-row">
                <div className="qty-control">
                  <button type="button" className="qty-btn" aria-label="Giảm số lượng" disabled={adding || quantity <= 1} onClick={() => setQuantity(q => Math.max(1, q - 1))} style={{ color: "var(--ink-secondary)" }}><GoogleSymbol name="remove" size={16} /></button>
                  <input type="text" value={Math.min(quantity, selectedVariant?.stockQuantity || 1)} readOnly aria-label="Số lượng" className="qty-input" />
                  <button type="button" className="qty-btn" aria-label="Tăng số lượng" disabled={adding || quantity >= Math.min(999, selectedVariant?.stockQuantity || 0)} onClick={() => setQuantity(q => Math.min(999, selectedVariant?.stockQuantity || 1, q + 1))} style={{ color: "var(--ink-primary)" }}><GoogleSymbol name="add" size={16} /></button>
                </div>
                <button type="button" disabled={!canAddToCart || adding || cart.loading || cart.busy} onClick={async () => {
                  if (!selectedVariant) return;
                  setAdding(true); setCartError("");
                  try { await cart.add(selectedVariant.id, Math.min(quantity, selectedVariant.stockQuantity)); setShowCartPopup(true); }
                  catch (error) { setCartError(error instanceof Error ? error.message : "Không thêm được sản phẩm"); }
                  finally { setAdding(false); }
                }} className="add-to-cart-btn"
                  style={{ opacity: canAddToCart ? 1 : 0.4, cursor: canAddToCart ? "pointer" : "not-allowed" }}>
                  {adding ? "ĐANG THÊM..." : "THÊM VÀO GIỎ HÀNG"}
                </button>
              </div>

              {cartError && <p className="cart-error" role="alert">{cartError}</p>}
              <div className="detail-stock-note">
                {selectedVariant && selectedVariant.stockQuantity > 0
                  ? `Còn hàng (${selectedVariant.stockQuantity})`
                  : "Hết hàng"}
              </div>
              <section className={galleryStyles.productDetails} aria-label="Thông tin sản phẩm">
                <ProductAccordion title="Mô tả">
                  <div className={galleryStyles.descriptionContent}>
                    <h3>{product.name}</h3>
                    <p style={{ whiteSpace: 'pre-wrap' }}>{product.description || 'Một gợi ý cho tủ đồ hằng ngày, dễ kết hợp cùng những món đồ yêu thích để tạo nên phong cách riêng.'}</p>
                    <dl>
                      {product.categoryName && <div><dt>Danh mục</dt><dd>{product.categoryName}</dd></div>}
                      {product.style && <div><dt>Phong cách</dt><dd>{product.style}</dd></div>}
                      {product.occasion && <div><dt>Dịp sử dụng</dt><dd>{product.occasion}</dd></div>}
                      {selectedColorObj && <div><dt>Màu đang chọn</dt><dd>{selectedColorObj.name}</dd></div>}
                      {product.sizes?.length > 0 && <div><dt>Kích cỡ</dt><dd>{product.sizes.map(size => size.name).join(', ')}</dd></div>}
                    </dl>
                    <h3>Gợi ý phối đồ</h3>
                    <p>Kết hợp cùng các thiết kế màu trung tính và phụ kiện tối giản để tạo tổng thể hài hòa. Tham khảo bảng kích cỡ để chọn size phù hợp với số đo của bạn.</p>
                  </div>
                </ProductAccordion>
                <ProductAccordion title="Chất liệu & chăm sóc">
                  <MaterialAndCareSample />
                </ProductAccordion>
                <ProductAccordion title="Giao hàng & đổi trả">
                  <DeliveryAndReturnsSample />
                </ProductAccordion>
                {hasReviews && product.reviews && <ProductAccordion title={`Đánh giá khách hàng (${product.reviewsCount})`}>
                  <div className={galleryStyles.reviewsDialog}>
                    <ProductReviews key={product.id} productId={product.id} initial={product.reviews} average={product.averageRating} count={product.reviewsCount} />
                  </div>
                </ProductAccordion>}
              </section>

            </div>
          </div>
        </div>{/* end product-page-layout */}
      </main>

      {/* ── SIMILAR PRODUCTS ── */}
      <ProductSimilar key={product.id} productId={product.id} />

      {/* ── FREQUENTLY BOUGHT TOGETHER ── */}
      <ProductBoughtTogether key={`bought-${product.id}`} productId={product.id} />
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
          <div className={galleryStyles.cartPopup} onClick={(e) => e.stopPropagation()}>
            <button
              style={{ position: "absolute", top: "24px", right: "24px", background: "none", border: "none", cursor: "pointer", color: "#111", display: "flex", alignItems: "center", justifyContent: "center" }}
              onClick={() => setShowCartPopup(false)}
            >
              <span className="material-symbols-outlined" style={{ fontSize: 24 }}>close</span>
            </button>
            <h2 style={{ fontSize: "1.2rem", fontWeight: 300, marginBottom: "8px", textTransform: "uppercase", letterSpacing: "1px" }}>Thêm vào giỏ hàng thành công</h2>

            <p style={{ fontWeight: 400, fontSize: "1rem", color: "#333", marginBottom: "4px" }}>Tổng số tiền ({Math.min(quantity, selectedVariant?.stockQuantity || 1)} sản phẩm): <span style={{ fontWeight: 500 }}>{money(displayPrice * Math.min(quantity, selectedVariant?.stockQuantity || 1))}</span></p>
            <p style={{ fontSize: "0.85rem", color: "#777", marginBottom: "32px", fontWeight: 300 }}>Phí giao hàng sẽ được tính tại bước đặt hàng.</p>

            {/* Added Product Info */}
            <div className={galleryStyles.cartProduct}>
              <div className={galleryStyles.cartImage}>
                {displayImage && <Image src={displayImage} alt={product.name} width={300} height={400} style={{ width: "100%", height: "auto", objectFit: "contain", borderRadius: "8px" }} />}
              </div>
              <div style={{ flex: 1, display: "flex", flexDirection: "column", justifyContent: "center" }}>
                <h3 style={{ fontSize: "1.2rem", fontWeight: 400, marginBottom: "12px", letterSpacing: "0.5px" }}>{product.name}</h3>
                <div style={{ fontSize: "0.95rem", color: "#555", fontWeight: 300, display: "flex", flexDirection: "column", gap: "6px" }}>
                  <p><span style={{ color: "#999", display: "inline-block", width: "80px" }}>Màu sắc:</span> {selectedColorObj?.name}</p>
                  <p><span style={{ color: "#999", display: "inline-block", width: "80px" }}>Kích cỡ:</span> {selectedSizeObj?.name}</p>
                  <p><span style={{ color: "#999", display: "inline-block", width: "80px" }}>Số lượng:</span> {Math.min(quantity, selectedVariant?.stockQuantity || 1)}</p>
                </div>
                <p style={{ fontSize: "1.2rem", fontWeight: 500, marginTop: "24px" }}>{formattedPrice}</p>
              </div>
            </div>

            {/* Actions */}
            <div className={galleryStyles.cartActions}>
              <button type="button" onClick={() => { setShowCartPopup(false); cart.openCart(); }} style={{ flex: 1, padding: "16px", backgroundColor: "#000", color: "#fff", border: "1px solid #000", fontWeight: 400, fontSize: "0.9rem", letterSpacing: "1px", textTransform: "uppercase", cursor: "pointer", transition: "all 0.3s", display: "flex", justifyContent: "center", alignItems: "center", textDecoration: "none" }}>
                Xem giỏ hàng
              </button>
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
