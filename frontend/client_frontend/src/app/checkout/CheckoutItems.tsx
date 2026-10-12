import Image from "next/image";
import { money, type CartItem } from "@/cart/types";

export default function CheckoutItems({ items }: { items: CartItem[] }) {
  return (
    <ul className="flex flex-col gap-4 mb-6">
      {items.map((item) => (
        <li key={item.variantId} className="flex items-center gap-4">
          <div className="relative shrink-0">
            <div className="w-16 h-20 bg-white rounded-md overflow-hidden border border-gray-200">
              {item.imageUrl ? (
                <Image unoptimized src={item.imageUrl} alt={item.name} width={64} height={80} className="w-full h-full object-cover" />
              ) : (
                <div className="w-full h-full" aria-hidden="true" />
              )}
            </div>
            <span className="absolute -top-2 -right-2 flex items-center justify-center w-5 h-5 bg-gray-600 text-white text-[11px] font-medium rounded-full shadow-sm">
              {item.quantity}
            </span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-[15px] font-normal text-gray-900 line-clamp-2">{item.name}</p>
            <p className="text-[13px] text-gray-400 mt-0.5">
              {item.colorName} / {item.sizeName}
            </p>
            {!item.purchasable && <p className="text-[13px] font-medium text-red-600 mt-1">{item.unavailableReason}</p>}
          </div>
          <span className="text-[15px] font-normal text-gray-900 whitespace-nowrap">
            {money(item.lineTotal)}
          </span>
        </li>
      ))}
    </ul>
  );
}
