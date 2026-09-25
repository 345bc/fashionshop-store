import Link from "next/link";
import Image from "next/image";

interface ComboCardProps {
  id: string;
  name: string;
  originalPrice: string;
  comboPrice: string;
  image: string;
  badge?: string;
  items: string[];
}

export default function ComboCard({
  id,
  name,
  originalPrice,
  comboPrice,
  image,
  badge,
  items,
}: ComboCardProps) {
  return (
    <div className="product-card combo-card">
      <Link href={`/combo/${id}`} className="product-media">
        {badge && <span className="product-badge badge-discount">{badge}</span>}
        <Image src={image} alt={name} width={400} height={500} style={{ objectFit: "cover", width: "100%", height: "auto" }} />
      </Link>
      <div className="product-info">
        <Link href={`/combo/${id}`} className="product-title combo-title">
          {name}
        </Link>
        <div className="combo-items">
          {items.map((item, idx) => (
            <span key={idx} className="combo-item-tag">+ {item}</span>
          ))}
        </div>
        <div className="combo-price-wrap">
          <span className="product-price">{comboPrice}</span>
          <span className="product-original-price">{originalPrice}</span>
        </div>
        <button className="btn btn-primary btn-sm add-quick-cart" style={{ marginTop: "12px", width: "100%" }}>
          Mua ngay Set này
        </button>
      </div>
    </div>
  );
}
