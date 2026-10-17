export default function ProductDetailSkeleton() {
  return (
    <main
      className="container mx-auto px-4 sm:px-6 lg:px-8 main-content"
      style={{ paddingBottom: 0 }}
      role="status"
      aria-label="Đang tải chi tiết sản phẩm"
      aria-busy="true"
    >
      <span className="sr-only">Đang tải chi tiết sản phẩm...</span>


      {/* ── OUTER 3/5 + 2/5 LAYOUT ── */}
      <div className="product-page-layout" style={{ marginBottom: 0 }} aria-hidden="true">
        {/* LEFT COL – 3/5: gallery skeleton */}
        <div className="product-left-col">
          <div className="gallery-container">
            {/* Thumbs */}
            <div
              className="gallery-thumbs"
              style={{
                width: "clamp(84px, 10vw, 120px)",
                display: "flex",
                flexDirection: "column",
                gap: "10px",
              }}
            >
              {[1, 2, 3, 4].map((i) => (
                <div
                  key={i}
                  className="w-full rounded bg-neutral-200 motion-safe:animate-pulse"
                  style={{ aspectRatio: "3 / 4" }}
                />
              ))}
            </div>

            {/* Main image */}
            <div
              className="gallery-main rounded bg-neutral-200 motion-safe:animate-pulse"
              style={{
                aspectRatio: "4 / 5",
                width: "100%",
                minWidth: 0,
                alignSelf: "flex-start",
              }}
            />
          </div>

          {/* Description Skeleton */}
          <section className="product-description-section" style={{ marginTop: "40px" }}>
            <div className="h-6 w-24 rounded bg-neutral-200 motion-safe:animate-pulse mb-3" />
            <div className="h-4 w-40 rounded bg-neutral-200 motion-safe:animate-pulse mb-6" />
            <div className="space-y-3">
              <div className="h-4 w-full rounded bg-neutral-200 motion-safe:animate-pulse" />
              <div className="h-4 w-5/6 rounded bg-neutral-200 motion-safe:animate-pulse" />
              <div className="h-4 w-4/6 rounded bg-neutral-200 motion-safe:animate-pulse" />
            </div>
          </section>
        </div>

        {/* RIGHT COL – 2/5: info skeleton */}
        <div className="product-right-col">
          <div className="detail-info detail-info-sticky">
            {/* Title */}
            <div className="h-8 w-4/5 rounded bg-neutral-200 motion-safe:animate-pulse mb-6" />

            {/* Colors */}
            <div className="detail-section">
              <div className="h-4 w-28 rounded bg-neutral-200 motion-safe:animate-pulse mb-3" />
              <div style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
                {[1, 2, 3, 4].map((i) => (
                  <div
                    key={i}
                    className="size-8 rounded-full bg-neutral-200 motion-safe:animate-pulse"
                  />
                ))}
              </div>
            </div>

            {/* Sizes */}
            <div className="detail-section" style={{ marginTop: "24px" }}>
              <div className="h-4 w-24 rounded bg-neutral-200 motion-safe:animate-pulse mb-3" />
              <div style={{ display: "flex", gap: "10px", flexWrap: "wrap" }}>
                {[1, 2, 3, 4].map((i) => (
                  <div
                    key={i}
                    className="h-10 w-14 rounded bg-neutral-200 motion-safe:animate-pulse"
                  />
                ))}
              </div>
            </div>

            {/* Price */}
            <div className="detail-price-row" style={{ margin: "24px 0" }}>
              <div className="h-8 w-44 rounded bg-neutral-200 motion-safe:animate-pulse" />
            </div>

            {/* Cart actions */}
            <div className="detail-cart-row" style={{ display: "flex", gap: "12px" }}>
              <div className="h-12 w-28 rounded bg-neutral-200 motion-safe:animate-pulse" />
              <div className="h-12 flex-1 rounded bg-neutral-200 motion-safe:animate-pulse" />
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
