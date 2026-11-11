import styles from "./DeliveryAndReturnsSample.module.css";

const methods = [
  { name: "Giao hàng tiêu chuẩn", time: "Dự kiến 2–4 ngày làm việc", fee: "30.000 VND", note: "Miễn phí từ 600.000 VND" },
  { name: "Giao hàng nhanh", time: "Dự kiến 1–2 ngày làm việc", fee: "50.000 VND", note: "Tùy khu vực giao hàng" },
  { name: "Nhận hàng tại cửa hàng", time: "Thông báo khi đơn hàng sẵn sàng", fee: "Miễn phí", note: "Trong giờ mở cửa" },
];

export default function DeliveryAndReturnsSample() {
  return <div className={styles.sample}>
    <h3>Giao hàng</h3>
    <p className={styles.caption}>Phương thức và mức phí minh họa.</p>
    <ul className={styles.methods}>
      {methods.map(method => <li key={method.name}>
        <div><h4>{method.name}</h4><p>{method.time}</p></div>
        <div className={styles.fee}><span>{method.fee}</span><p>{method.note}</p></div>
      </li>)}
    </ul>
    <p>Phí và thời gian giao hàng thực tế được hiển thị khi đặt hàng, tùy địa chỉ nhận.</p>
    <h3 className={styles.returns}>Đổi trả</h3>
    <p>Nội dung mẫu: hỗ trợ đổi trả trong vòng 14 ngày kể từ khi nhận hàng.</p>
    <p>Sản phẩm cần còn nguyên tem nhãn, chưa qua sử dụng hoặc giặt và có thông tin đơn hàng kèm theo.</p>
    <p>Liên hệ bộ phận chăm sóc khách hàng để được hướng dẫn trước khi gửi sản phẩm về.</p>
  </div>;
}
