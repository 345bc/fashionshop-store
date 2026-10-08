"use client";

import { useEffect, useState } from "react";
import type { ApiResponse } from "../type/api";
import { getColorOptions, type ColorOption } from "../service/colorService";
import { getSize } from "@/service/sizeServive";

type FilterState = {
  types: string[];
  sizes: string[];
  price: string;
};

interface FilterSidebarProps {
  isOpen: boolean;
  onClose: () => void;
  value?: FilterState;
  onChange?: (value: FilterState) => void;
  resultCount?: number;
  resultsLoading?: boolean;
  selectedColorIds?: number[];
  selectedSizeIds?: number[];
  onToggleColor?: (id: number) => void;
  onToggleSize?: (id: number) => void;
  onReset?: () => void;
}

interface sizeProps {
  id: number,
  name: string
}



const priceOptions: Array<[string, string]> = [
  ["all", "Tất cả"],
  ["under199", "Dưới 199.000 VND"],
  ["199to299", "199.000 VND - 299.000 VND"],
  ["299to399", "299.000 VND - 399.000 VND"],
  ["399to499", "399.000 VND - 499.000 VND"],
  ["499to799", "499.000 VND - 799.000 VND"],
  ["799to999", "799.000 VND - 999.000 VND"],
  ["over999", "Trên 999.000 VND"],
];

export default function FilterSidebar({
  isOpen, onClose, value, onChange, resultCount = 0, resultsLoading = false,
  selectedColorIds = [], selectedSizeIds = [], onToggleColor, onToggleSize, onReset,
}: FilterSidebarProps) {
  const current: FilterState = {
    types: value?.types || [],
    sizes: value?.sizes || [],
    price: value?.price || "all",
  };
  const emit = (next: FilterState) => onChange?.(next);

  const [sizesResponse, setSizesResponse] = useState<ApiResponse<sizeProps[]> | null>(null);
  const [colorOptions, setColorOptions] = useState<ColorOption[]>([]);
  const [colorsLoading, setColorsLoading] = useState(true);
  const [colorError, setColorError] = useState("");
  const [colorRetry, setColorRetry] = useState(0);

  function onRetryColors() {
    setColorsLoading(true);
    setColorError("");
    setColorRetry((value) => value + 1);
  }

  useEffect(() => {
    const controller = new AbortController();
    let retryTimer: ReturnType<typeof setTimeout> | undefined;

    async function loadColors() {
      setColorsLoading(true);
      setColorError("");

      try {
        const colors = await getColorOptions(controller.signal);
        if (controller.signal.aborted) return;
        setColorOptions(colors);
      } catch (err) {
        if (controller.signal.aborted) return;

        if (err instanceof TypeError) {
          retryTimer = setTimeout(() => setColorRetry((value) => value + 1), 5000);
        } else {
          setColorError(err instanceof Error ? err.message : "Không tải được màu");
        }
      } finally {
        if (!controller.signal.aborted && retryTimer === undefined) {
          setColorsLoading(false);
        }
      }
    }

    void loadColors();

    return () => {
      controller.abort();
      clearTimeout(retryTimer);
    };
  }, [colorRetry]);

  useEffect(() => {
    const fetchSizes = async () => {
      try {
        const response = await getSize();
        setSizesResponse(response);
      } catch (error) {
        console.error(error);
      }
    };

    fetchSizes();
  }, []);



  return (
    <>
      {/* Backdrop */}
      <div
        className={`fixed inset-0 z-100 bg-black/40 backdrop-blur-sm transition-opacity duration-300 ${isOpen ? "opacity-100 visible" : "opacity-0 invisible"}`}
        onClick={onClose}
      />

      {/* Sidebar Panel */}
      <aside
        className={`fixed inset-y-0 right-0 z-110 flex w-full max-w-105 flex-col bg-white shadow-2xl transition-transform duration-400 ease-out ${isOpen ? "translate-x-0" : "translate-x-full"}`}
        aria-hidden={!isOpen}
      >
        {/* Header */}
        <div className="flex items-center justify-between border-b border-black/10 px-7 py-6">
          <div>
            <p className="mb-1 text-[11px] font-extrabold tracking-[0.15em] text-black/40 uppercase">Tinh chỉnh kết quả</p>
            <h2 className="text-2xl font-bold tracking-tight text-black">Bộ lọc</h2>
          </div>
          <button
            className="flex size-11 items-center justify-center rounded-full bg-black/5 text-black transition-colors hover:bg-black/10 active:scale-95"
            onClick={onClose}
            aria-label="Đóng bộ lọc"
          >
            <span className="material-symbols-outlined" style={{ fontSize: 24, strokeWidth: 1.5 }}>close</span>
          </button>
        </div>

        {/* Scrollable Body */}
        <div className="flex-1 overflow-y-auto px-7 py-6 space-y-10">

          {/* Types Section */}
          {/* <section>
            <div className="mb-5 flex items-center justify-between border-b border-black/5 pb-3">
              <span className="text-[14px] font-bold uppercase tracking-wider text-black">Loại sản phẩm</span>
              {current.types.length > 0 && (
                <span className="flex size-6 items-center justify-center rounded-full bg-black text-[12px] font-bold text-white">{current.types.length}</span>
              )}
            </div>
            <div className="space-y-4">
              {typeOptions.map((item) => (
                <label key={item} className="group flex cursor-pointer items-center space-x-3.5">
                  <div className={`flex size-5 items-center justify-center rounded-[4px] border transition-colors ${current.types.includes(item) ? "border-black bg-black text-white" : "border-black/20 bg-white group-hover:border-black/50"}`}>
                    {current.types.includes(item) && <span className="material-symbols-outlined" style={{ fontSize: 14, strokeWidth: 4 }}>check</span>}
                  </div>
                  <span className={`text-[15px] transition-colors ${current.types.includes(item) ? "font-semibold text-black" : "font-medium text-black/70 group-hover:text-black"}`}>{item}</span>
                  <input type="checkbox" className="hidden" checked={current.types.includes(item)} onChange={() => toggleArray("types", item)} />
                </label>
              ))}
            </div>
          </section> */}

          {/* Sizes Section */}
          <section>
            <div className="mb-5 flex items-center justify-between border-b border-black/5 pb-3">
              <span className="text-[14px] font-bold uppercase tracking-wider text-black">Kích cỡ</span>
              {selectedSizeIds.length > 0 && (
                <span className="flex size-6 items-center justify-center rounded-full bg-black text-[12px] font-bold text-white">{selectedSizeIds.length}</span>
              )}
            </div>
            <div className="grid grid-cols-3 gap-3">
              {sizesResponse?.data ? (
                sizesResponse.data.map((sizeItem) => (
                  <button
                    key={sizeItem.id}
                    onClick={() => onToggleSize?.(sizeItem.id)}
                    className={`flex h-10.5 items-center justify-center rounded-xl border text-[14px] font-bold transition-all ${selectedSizeIds.includes(sizeItem.id)
                      ? "border-black bg-black text-white shadow-md shadow-black/20"
                      : "border-black/15 bg-transparent text-black/70 hover:border-black/40 hover:bg-black/5 hover:text-black"
                      }`}
                  >
                    {sizeItem.name}
                  </button>
                ))
              ) : (
                <>
                  {[1, 2, 3, 4, 5, 6].map((i) => (
                    <div
                      key={i}
                      className="h-10.5 rounded-xl bg-black/5 animate-pulse" />
                  ))}
                </>
              )}
            </div>
          </section>

          {/* Colors Section */}
          <section>
            <div className="mb-5 flex items-center justify-between border-b border-black/5 pb-3">
              <span className="text-[14px] font-bold uppercase tracking-wider text-black">Màu sắc</span>
              {selectedColorIds.length > 0 && (
                <span className="flex size-6 items-center justify-center rounded-full bg-black text-[12px] font-bold text-white">{selectedColorIds.length}</span>
              )}
            </div>
            <div className="grid grid-cols-2 gap-y-4 gap-x-6">
              {colorError ? (
                <div role="alert" className="col-span-2 text-sm text-red-700">
                  <p>{colorError}</p>
                  {onRetryColors && <button type="button" className="mt-2 underline" onClick={onRetryColors}>Thử lại</button>}
                </div>
              ) : !colorsLoading ? (
                colorOptions.length === 0 ? <p className="col-span-2 text-sm text-black/50">Chưa có màu sắc.</p> :
                  colorOptions.map((item) => (
                    <label key={item.id} className="group flex cursor-pointer items-center space-x-3">
                      <div
                        className={`flex size-5.5 items-center justify-center rounded-md border shadow-sm transition-all ${selectedColorIds.includes(item.id) ? "border-black ring-2 ring-black/20 scale-105" : "border-black/20 group-hover:border-black/40"}`}
                        style={{ backgroundColor: item.hexCode }}
                      >
                        {selectedColorIds.includes(item.id) && (
                          <span className="material-symbols-outlined text-white mix-blend-difference" style={{ fontSize: 14, strokeWidth: 4 }}>
                            check
                          </span>
                        )}
                      </div>
                      <span className={`text-[15px] transition-colors ${selectedColorIds.includes(item.id) ? "font-semibold text-black" : "font-medium text-black/70 group-hover:text-black"}`}>
                        {item.name}
                      </span>
                      <input
                        type="checkbox"
                        className="sr-only"
                        checked={selectedColorIds.includes(item.id)}
                        onChange={() => onToggleColor?.(item.id)}
                      />
                    </label>
                  ))
              ) : (
                <>
                  {[1, 2, 3, 4, 5, 6].map((i) => (
                    <div key={i} className="flex items-center space-x-3">
                      <div className="size-5.5 rounded-md bg-black/5 animate-pulse" />
                      <div className="h-4 w-16 rounded bg-black/5 animate-pulse" />
                    </div>
                  ))}
                </>
              )}
            </div>
          </section>

          {/* Price Section */}
          <section>
            <div className="mb-5 flex items-center justify-between border-b border-black/5 pb-3">
              <span className="text-[14px] font-bold uppercase tracking-wider text-black">Giá</span>
            </div>
            <div className="grid grid-cols-2 gap-y-4 gap-x-2">
              {priceOptions.map(([id, label]) => (
                <label key={id} className="group flex cursor-pointer items-center space-x-2">
                  <div className={`flex size-5 shrink-0 items-center justify-center rounded-full border transition-colors ${current.price === id ? "border-black bg-white" : "border-black/20 bg-white group-hover:border-black/50"}`}>
                    <div className={`size-2.5 rounded-full bg-black transition-transform ${current.price === id ? "scale-100" : "scale-0"}`} />
                  </div>
                  <span className={`text-[13px] leading-tight transition-colors ${current.price === id ? "font-semibold text-black" : "font-medium text-black/70 group-hover:text-black"}`}>{label}</span>
                  <input type="radio" className="hidden" name="catalog-price" checked={current.price === id} onChange={() => emit({ ...current, price: id })} />
                </label>
              ))}
            </div>
          </section>

        </div>

        {/* Footer */}
        <div className="border-t border-black/10 bg-gray-50/80 px-7 py-6 backdrop-blur-lg">
          <div className="flex items-center gap-4">
            <button
              className="flex-1 rounded-xl bg-[#e5e5e5] py-4 text-[15px] font-bold text-black transition-colors hover:bg-[#d4d4d4] active:scale-[0.98]"
              onClick={() => onReset ? onReset() : emit({ types: [], sizes: [], price: "all" })}
            >
              Đặt lại
            </button>
            <button
              className="flex-2 rounded-xl bg-black py-4 text-[15px] font-bold text-white shadow-xl shadow-black/20 transition-all hover:bg-[#1a1a1a] active:scale-[0.98] disabled:opacity-70"
              onClick={onClose}
              disabled={resultsLoading}
            >
              {resultsLoading ? "Đang tải..." : `Xem ${resultCount} sản phẩm`}
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
