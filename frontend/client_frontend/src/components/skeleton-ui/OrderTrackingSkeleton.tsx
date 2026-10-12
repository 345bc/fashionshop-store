export default function OrderTrackingSkeleton() {
  return (
    <div role="status" aria-label="Đang tra cứu đơn hàng" className="animate-pulse space-y-6 border-t border-black/10 pt-6">
      <div className="h-6 w-2/3 rounded bg-black/10" />
      <div className="h-20 rounded bg-black/5" />
      <div className="h-28 rounded bg-black/5" />
      <div className="ml-auto h-7 w-1/3 rounded bg-black/10" />
    </div>
  );
}
