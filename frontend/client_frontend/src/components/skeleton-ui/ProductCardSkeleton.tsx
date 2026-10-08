export default function ProductCardSkeleton() {
  return (
    <div role="status" aria-label="Đang tải sản phẩm">
      <span className="sr-only">Đang tải sản phẩm...</span>
      <div className="modern-products-grid" aria-hidden="true">
        {Array.from({ length: 8 }, (_, index) => (
          <div key={index} className={`modern-product-card flex h-full flex-col motion-safe:animate-pulse ${index >= 4 ? "max-[820px]:hidden" : ""}`}>
            <div className="modern-product-media w-full bg-neutral-200" style={{ aspectRatio: "3/4" }} />
            <div className="modern-product-info flex-1">
              <div className="h-3 w-12 rounded bg-neutral-200" />
              <div className="mb-3 mt-2 h-5 w-4/5 rounded bg-neutral-200" />
              <div className="modern-product-bottom">
                <div className="h-5 w-24 rounded bg-neutral-200" />
                <div className="flex gap-1">
                  <div className="size-7 rounded-full bg-neutral-200" />
                  <div className="size-7 rounded-full bg-neutral-200" />
                  <div className="size-7 rounded-full bg-neutral-200" />
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
