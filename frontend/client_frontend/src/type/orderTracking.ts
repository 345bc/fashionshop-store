export type OrderTracking = {
  code: string;
  status: string;
  paymentStatus: string;
  createdAt: string;
  totalAmount: number;
  items: { name: string; sku: string; quantity: number; lineTotal: number }[];
};
