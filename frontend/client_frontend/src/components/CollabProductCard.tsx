import Link from "next/link";
import Image from "next/image";

interface CollabProductCardProps {
  id: string;
  name: string;
  price: string;
  image: string;
  colors: string[];
}

export default function CollabProductCard({
  id,
  name,
  price,
  image,
  colors,
}: CollabProductCardProps) {
  return (
    <div className="collab-product-card group">
      <Link href={`/product/${id}`} className="collab-media">
        <Image 
          src={image} 
          alt={name} 
          width={400} 
          height={500} 
          style={{ objectFit: "cover", width: "100%", height: "100%", borderRadius: "12px" }} 
          className="collab-img transition-transform duration-500 group-hover:scale-105"
        />
      </Link>
      <div className="collab-info">
        {colors && colors.length > 0 && (
          <div className="collab-colors">
            {colors.map((color, index) => (
              <span key={index} className="color-swatch" style={{ backgroundColor: color }}></span>
            ))}
          </div>
        )}
        <Link href={`/product/${id}`} className="collab-title">
          {name}
        </Link>
        <div className="collab-price">{price}</div>
      </div>
    </div>
  );
}
