import styles from "./MaterialAndCareSample.module.css";

const instructions = [
  { label: "Không giặt bằng nước", path: "M3 7l2 13h14l2-13M4 9c2-3 4 3 6 0s4 3 6 0 3 0 4 0", crossed: true },
  { label: "Không sử dụng chất tẩy", path: "M12 3L2 21h20L12 3Z", crossed: true },
  { label: "Không sấy bằng máy", path: "M3 3h18v18H3ZM12 4a8 8 0 1 0 0 16 8 8 0 0 0 0-16", crossed: true },
  { label: "Ủi nhiệt độ thấp, tối đa 110°C", path: "M5 5h12l4 14H3l4-9h11M10 15h.1", crossed: false },
  { label: "Giặt khô chuyên nghiệp", path: "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20M9 17V7h4a3 3 0 0 1 0 6H9", crossed: false },
  { label: "Phơi treo tự nhiên trong bóng râm", path: "M3 3h18v18H3ZM12 6v12", crossed: false },
];

export default function MaterialAndCareSample() {
  return <div className={styles.sample}>
    <div className={styles.composition}>
      <h3>Thành phần chất liệu — mẫu</h3>
      <p>Vải ngoài: 60% len tái chế, 35% polyester tái chế, 5% sợi khác.</p>
      <p>Lớp lót: 100% polyester.</p>
    </div>
    <h3>Hướng dẫn chăm sóc</h3>
    <ul className={styles.instructions}>
      {instructions.map(item => <li key={item.label}>
        <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d={item.path} />
          {item.crossed && <path d="M2 2l20 20M22 2L2 22" />}
        </svg>
        <span>{item.label}</span>
      </li>)}
    </ul>
    <p className={styles.note}>Tham khảo nhãn chăm sóc đính kèm sản phẩm để biết hướng dẫn phù hợp.</p>
  </div>;
}
