import { useState } from "react";
import Link from "next/link";
import Image from "next/image";

interface ProductCardProps {
  id: string;
  name: string;
  price: string;
  image: string;
  badge?: string;
  rating: number;
  reviewsCount: number;
}

const colors = [
  { name: "Ivory", value: "#ece7df" },
  { name: "Sage", value: "#9aa38f" },
  { name: "Charcoal", value: "#272727" },
];

export default function ProductCard({ id, name, price, image, badge, rating, reviewsCount }: ProductCardProps) {
  const [selectedColor, setSelectedColor] = useState(colors[0].name);

  return (
    <article className="product-card modern-product-card " style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div className="product-media modern-product-media " style={{ width: '100%', aspectRatio: '3/4', position: 'relative' }}>
        <Link href={`/product/${id}`} aria-label={`Xem ${name}`} style={{ display: 'block', width: '100%', height: '100%' }}>
          <Image src={image} alt={name} width={520} height={680} className="product-card-image bg-white" />
        </Link>
        {badge && <span className="product-badge modern-badge">{badge}</span>}
      </div>
      <div className="modern-product-info" style={{ display: 'flex', flexDirection: 'column', flex: 1 }}>
        <Link href={`/product/${id}`} className="product-card-copy" aria-label={`Xem chi tiết ${name}`} style={{ flex: 1 }}>
          <div className="product-meta-line">
            <span>New season</span>
            <span>★ {rating.toFixed(1)} ({reviewsCount})</span>
          </div>
          <span className="modern-product-title">{name}</span>
        </Link>
        <div className="modern-product-bottom">
          <Link href={`/product/${id}`} className="modern-product-price">{price}</Link>
          <div className="product-color-controls">
            <span className="selected-color-label">Màu: <strong>{selectedColor}</strong></span>
            <div className="mini-swatches" role="group" aria-label="Chọn màu sắc">
              {colors.map((color) => (
                <button
                  type="button"
                  key={color.name}
                  className={selectedColor === color.name ? "active" : ""}
                  aria-label={`Chọn màu ${color.name}`}
                  aria-pressed={selectedColor === color.name}
                  title={color.name}
                  onClick={() => setSelectedColor(color.name)}
                >
                  <span style={{ background: color.value }} />
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>
    </article>
  );
}
