import styles from "./CartSkeleton.module.css";

export default function CartSkeleton() {
  return <div role="status" aria-label="Đang tải giỏ hàng" aria-busy="true">
    {[0, 1, 2].map(row => <div key={row} className={styles.item} aria-hidden="true">
      <span className={`${styles.block} ${styles.checkbox}`} />
      <span className={`${styles.block} ${styles.image}`} />
      <div className={styles.info}>
        <span className={`${styles.block} ${styles.title}`} />
        <span className={`${styles.block} ${styles.subtitle}`} />
        <span className={`${styles.block} ${styles.price}`} />
        <span className={`${styles.block} ${styles.quantity}`} />
        <span className={`${styles.block} ${styles.total}`} />
      </div>
    </div>)}
  </div>;
}

export function CartSummarySkeleton() {
  return <div className={styles.summary} role="status" aria-label="Đang tải tổng tiền" aria-busy="true">
    <span className={`${styles.block} ${styles.subtitle}`} aria-hidden="true" />
    <div className={styles.summaryTotal} aria-hidden="true"><span className={`${styles.block} ${styles.price}`} /><span className={`${styles.block} ${styles.total}`} /></div>
    <span className={`${styles.block} ${styles.button}`} aria-hidden="true" />
  </div>;
}
