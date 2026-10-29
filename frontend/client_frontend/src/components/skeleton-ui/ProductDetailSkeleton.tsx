import styles from "@/app/product/[id]/ProductGallery.module.css";

export default function ProductDetailSkeleton() {
  return (
    <main className={`main-content ${styles.page}`} role="status" aria-label="Đang tải chi tiết sản phẩm" aria-busy="true">
      <span className="sr-only">Đang tải chi tiết sản phẩm...</span>
      <div className={`product-page-layout ${styles.layout}`} aria-hidden="true">
        <div className={styles.stage}>
          <div className={`${styles.imagePanel} bg-neutral-200 motion-safe:animate-pulse`} />
          <div className={`${styles.imagePanel} ${styles.secondImage} bg-neutral-200 motion-safe:animate-pulse`} />
        </div>
        <div className="product-right-col">
          <div className="detail-info detail-info-sticky">
            <div className={styles.thumbnailStrip}>
              <div className={styles.stripTrack}>
                {[1, 2, 3, 4, 5].map(i => <div key={i} className="h-19 w-14 shrink-0 bg-neutral-200 motion-safe:animate-pulse" />)}
              </div>
            </div>
            <div className="h-4 w-20 bg-neutral-200 motion-safe:animate-pulse mb-6" />
            <div className="h-6 w-4/5 bg-neutral-200 motion-safe:animate-pulse mb-3" />
            <div className="h-5 w-32 bg-neutral-200 motion-safe:animate-pulse mb-8" />
            <div className="flex gap-3 mb-8">
              {[1, 2, 3, 4].map(i => <div key={i} className="size-6 bg-neutral-200 motion-safe:animate-pulse" />)}
            </div>
            <div className="h-20 w-full bg-neutral-200 motion-safe:animate-pulse mb-8" />
            <div className="h-12 w-full bg-neutral-200 motion-safe:animate-pulse mb-8" />
            <div className="space-y-4">
              {[1, 2, 3].map(i => <div key={i} className="h-4 w-full bg-neutral-200 motion-safe:animate-pulse" />)}
            </div>
          </div>
        </div>
      </div>
    </main>
  );
}
