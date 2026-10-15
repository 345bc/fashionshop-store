import Header from "@/components/Header";
import Footer from "@/components/Footer";
import Link from "next/link";

export default function OrderSuccessPage() {
  return (
    <>
      <Header />
      <main className="min-h-[75vh] flex items-center justify-center font-sans bg-gray-50 py-12 px-5">
        <div className="w-full max-w-125 bg-white rounded-2xl shadow-[0_4px_24px_rgba(0,0,0,0.04)] border border-gray-100 p-8 sm:p-10 text-center relative overflow-hidden">

          {/* Subtle top decoration */}
          <div className="absolute top-0 left-0 w-full h-1 bg-black"></div>

          {/* Icon */}
          <div className="mx-auto w-16 h-16 bg-black text-white rounded-full flex items-center justify-center mb-6 shadow-md">
            <span className="material-symbols-outlined text-[32px] font-bold">check</span>
          </div>

          <h1 className="text-2xl sm:text-3xl font-bold text-gray-900 mb-2 uppercase tracking-wide">Đặt Hàng Thành Công</h1>
          <p className="text-[15px] text-gray-500 mb-8 leading-relaxed">
            Cảm ơn bạn đã mua sắm tại Zella. Đơn hàng của bạn đang được xử lý và sẽ sớm được giao.
          </p>

          {/* Info Card */}
          <div className="bg-gray-50 rounded-xl p-5 mb-8 text-left border border-gray-100">
            <div className="flex justify-between items-center mb-3 pb-3 border-b border-gray-200">
              <span className="text-sm text-gray-500 font-medium">Mã đơn hàng</span>
              <strong className="text-[15px] text-black">#ZEL91284</strong>
            </div>
            <div className="flex justify-between items-center mb-3 pb-3 border-b border-gray-200">
              <span className="text-sm text-gray-500 font-medium">Thanh toán</span>
              <strong className="text-[15px] text-black">VNPay</strong>
            </div>
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-500 font-medium">Tổng cộng</span>
              <strong className="text-lg text-black font-bold">750.000  VND</strong>
            </div>
          </div>

          {/* Actions */}
          <div className="flex flex-col gap-3">
            <Link href="/orders" className="w-full py-3.5 bg-black text-white text-[15px] font-semibold rounded-xl hover:bg-gray-900 transition-colors shadow-sm">
              Theo dõi đơn hàng
            </Link>
            <Link href="/products" className="w-full py-3.5 bg-white text-gray-900 text-[15px] font-semibold rounded-xl hover:bg-gray-50 transition-colors border border-gray-200">
              Tiếp tục mua sắm
            </Link>
          </div>

        </div>
      </main>
      <Footer />
    </>
  );
}

