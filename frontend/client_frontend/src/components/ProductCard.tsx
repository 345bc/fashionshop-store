import { useState } from "react";
import Link from "next/link";
import Image from "next/image";

interface ProductCardProps {
  id: string;
  slug: string;
  name: string;
  price: string;
  image: string;
  badge?: string;
  rating?: number;
  reviewsCount?: number;
  colors?: {
    id: number;
    name: string;
    hexCode: string;
    imageUrl: string | null;
  }[];
}

export default function ProductCard({ slug, name, price, image, badge, rating, reviewsCount, colors = [] }: ProductCardProps) {
  const [selectedColorId, setSelectedColorId] = useState<number | null>(null);
  const selectedColor = colors.find((color) => color.id === selectedColorId) ?? colors[0];
  const displayImage = selectedColor?.imageUrl || image;
  const displayBadge = badge === "NEW" ? "Mới" : badge;

  return (
    <article className="product-card modern-product-card " style={{ display: 'flex', flexDirection: 'column', height: '100%' }}>
      <div className="product-media modern-product-media " style={{ width: '100%', aspectRatio: '3/4', position: 'relative' }}>
        <Link href={`/product/${slug}`} aria-label={`Xem ${name}`} style={{ display: 'block', width: '100%', height: '100%' }}>
          {displayImage ? (
            <Image src={displayImage} alt={selectedColor ? `${name} - ${selectedColor.name}` : name}
              width={520} height={680} className="product-card-image bg-white" />
          ) : (
            <div className="flex h-full items-center justify-center bg-neutral-100 text-sm text-neutral-500">
              Chưa có ảnh
            </div>
          )}
        </Link>
        {displayBadge && <span className="product-badge modern-badge" style={{ zIndex: 2, pointerEvents: "none" }}>{displayBadge}</span>}
      </div>
      <div className="modern-product-info" style={{ display: 'flex', flexDirection: 'column', flex: 1 }}>
        <Link href={`/product/${slug}`} className="product-card-copy" aria-label={`Xem chi tiết ${name}`} style={{ flex: 1 }}>
          <div className="product-meta-line">
            <span>Zella</span>
            {rating != null && reviewsCount != null && (
              <span>★ {rating.toFixed(1)} ({reviewsCount})</span>
            )}
          </div>
          <span className="modern-product-title">{name}</span>
        </Link>
        <div className="modern-product-bottom">
          <Link href={`/product/${slug}`} className="modern-product-price">{price}</Link>
          {selectedColor && (
            <div className="product-color-controls">
              <span className="selected-color-label">Màu: <strong>{selectedColor.name}</strong></span>
              <div className="mini-swatches" role="group" aria-label="Chọn màu sắc">
                {colors.map((color) => (
                  <button
                    type="button"
                    key={color.id}
                    className={selectedColor.id === color.id ? "active" : ""}
                    aria-label={`Chọn màu ${color.name}`}
                    aria-pressed={selectedColor.id === color.id}
                    title={color.name}
                    onClick={() => setSelectedColorId(color.id)}
                    onMouseEnter={() => setSelectedColorId(color.id)}
                  >
                    <span style={{ background: color.hexCode }} />
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </article>
  );
}
