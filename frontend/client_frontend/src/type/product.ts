export type ProductCardData = {
  id: number;
  name: string;
  slug: string;
  basePrice: number;
  imageUrl: string | null;
  badge?: string | null;
  colors: {
    id: number;
    name: string;
    hexCode: string;
    imageUrl: string | null;
  }[];
};
