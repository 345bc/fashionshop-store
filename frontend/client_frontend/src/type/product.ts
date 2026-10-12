export type ProductCardData = {
  id: number;
  name: string;
  slug: string;
  basePrice: number;
  salePrice: number | null;
  discountPercent: number | null;
  imageUrl: string | null;
  badge?: string | null;
  averageRating?: number;
  reviewsCount?: number;
  colors: {
    id: number;
    name: string;
    hexCode: string;
    imageUrl: string | null;
  }[];
};
