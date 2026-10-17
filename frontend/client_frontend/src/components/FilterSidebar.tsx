"use client";

import { useEffect, useState, type ReactNode } from "react";
import type { ApiResponse } from "../type/api";
import { getColorOptions, type ColorOption } from "../service/colorService";
import { getSize } from "@/service/sizeServive";

type FilterState = {
  types: string[];
  sizes: string[];
  price: string;
};

interface FilterSidebarProps {
  showCategoryTypes?: boolean;
  categoryOptions?: { id: number; name: string; parentName: string | null }[];
  categoryParentName?: string;
  categoriesLoading?: boolean;
  categoriesError?: string;
  onRetryCategories?: () => void;
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

function FilterGroup({ title, count = 0, children }: { title: string; count?: number; children: ReactNode }) {
  return <details open className="group/filter border-b border-neutral-100 pb-6">
    <summary className="flex cursor-pointer list-none items-center justify-between gap-4 py-2 text-[14px] font-semibold text-neutral-800 outline-offset-4 [&::-webkit-details-marker]:hidden">
      <span className="flex items-center gap-2">{title}{count > 0 && <span className="rounded-full bg-neutral-100 px-2 py-0.5 text-[11px] font-medium text-neutral-600">{count}</span>}</span>
      <span aria-hidden="true" className="flex size-7 items-center justify-center text-xl font-normal text-neutral-500"><span className="group-open/filter:hidden">+</span><span className="hidden group-open/filter:inline">−</span></span>
    </summary>
    <div className="pt-4">{children}</div>
  </details>;
}

export default function FilterSidebar({
  showCategoryTypes = true, categoryOptions = [], categoryParentName = "", categoriesLoading = false, categoriesError = "", onRetryCategories,
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
            <p className="mb-1 text-[11px] font-medium tracking-[0.15em] text-neutral-400 uppercase">Tinh chỉnh kết quả</p>
            <h2 className="text-[22px] font-semibold tracking-tight text-neutral-900">Bộ lọc</h2>
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
        <div className="flex-1 overflow-y-auto px-6 py-4 space-y-4">

          {(current.types.length > 0 || selectedSizeIds.length > 0 || selectedColorIds.length > 0 || current.price !== "all") && <FilterGroup title="Đang dùng bộ lọc">
            <div className="flex flex-wrap items-center gap-2">
              {[
                ...current.types.map(id => ({ key: `category-${id}`, label: categoryOptions.find(c => String(c.id) === id)?.name ?? "Danh mục đã chọn", remove: () => emit({ ...current, types: current.types.filter(v => v !== id) }) })),
                ...selectedSizeIds.map(id => ({ key: `size-${id}`, label: `Cỡ ${sizesResponse?.data.find(s => s.id === id)?.name ?? id}`, remove: () => onToggleSize?.(id) })),
                ...selectedColorIds.map(id => ({ key: `color-${id}`, label: colorOptions.find(c => c.id === id)?.name ?? `Màu ${id}`, remove: () => onToggleColor?.(id) })),
                ...(current.price === "all" ? [] : [{ key: "price", label: priceOptions.find(([id]) => id === current.price)?.[1] ?? current.price, remove: () => emit({ ...current, price: "all" }) }]),
              ].map(chip => <button key={chip.key} type="button" onClick={chip.remove} aria-label={`Bỏ bộ lọc ${chip.label}`} className="flex items-center gap-3 rounded-full border border-black/15 px-3 py-2 text-sm hover:bg-black/5">{chip.label}<span aria-hidden="true">×</span></button>)}
              <button type="button" className="px-2 py-2 text-sm text-blue-600 hover:underline" onClick={onReset}>Xóa tất cả</button>
            </div>
          </FilterGroup>}
          {showCategoryTypes && <FilterGroup title="Loại sản phẩm" count={current.types.length}>
            {categoryParentName && <p className="mb-4 text-xs text-neutral-400">Danh mục thuộc {categoryParentName}</p>}
            {categoriesLoading ? <div className="space-y-3" aria-label="Đang tải loại sản phẩm">{[1,2,3].map(i => <div key={i} className="h-5 w-3/4 rounded bg-black/5 motion-safe:animate-pulse" />)}</div>
              : categoriesError ? <div role="alert" className="text-sm text-red-700">{categoriesError} <button type="button" className="underline" onClick={onRetryCategories}>Thử lại</button></div>
              : <div className="space-y-4">{categoryOptions.map(category => <label key={category.id} className="flex cursor-pointer items-center gap-3 text-[15px] text-black/75">
                <input type="checkbox" className="size-5 shrink-0 accent-black" checked={current.types.includes(String(category.id))} onChange={() => {
                  const id = String(category.id);
                  emit({ ...current, types: current.types.includes(id) ? current.types.filter(v => v !== id) : [...current.types, id] });
                }} />
                <span className={current.types.includes(String(category.id)) ? "font-medium text-neutral-900" : "text-neutral-600"}>{category.name}</span>
              </label>)}{!categoryOptions.length && <p className="text-sm text-black/50">Chưa có loại sản phẩm.</p>}</div>}
          </FilterGroup>}

          {/* Sizes Section */}
          <FilterGroup title="Kích cỡ" count={selectedSizeIds.length}>
            <div className="grid grid-cols-3 gap-3">
              {sizesResponse?.data ? (
                sizesResponse.data.map((sizeItem) => (
                  <button
                    key={sizeItem.id}
                    onClick={() => onToggleSize?.(sizeItem.id)}
                    className={`flex h-10.5 items-center justify-center rounded-lg border text-[14px] font-medium transition-all ${selectedSizeIds.includes(sizeItem.id)
                      ? "border-neutral-900 bg-neutral-900 text-white"
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
          </FilterGroup>

          {/* Colors Section */}
          <FilterGroup title="Màu sắc" count={selectedColorIds.length}>
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
                      <span className={`text-[15px] transition-colors ${selectedColorIds.includes(item.id) ? "font-medium text-neutral-900" : "font-normal text-neutral-600 group-hover:text-neutral-900"}`}>
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
          </FilterGroup>

          {/* Price Section */}
          <FilterGroup title="Giá" count={current.price === "all" ? 0 : 1}>
            <div className="grid grid-cols-2 gap-y-4 gap-x-2">
              {priceOptions.map(([id, label]) => (
                <label key={id} className="group flex cursor-pointer items-center space-x-2">
                  <div className={`flex size-5 shrink-0 items-center justify-center rounded-full border transition-colors ${current.price === id ? "border-black bg-white" : "border-black/20 bg-white group-hover:border-black/50"}`}>
                    <div className={`size-2.5 rounded-full bg-black transition-transform ${current.price === id ? "scale-100" : "scale-0"}`} />
                  </div>
                  <span className={`text-[13px] leading-tight transition-colors ${current.price === id ? "font-medium text-neutral-900" : "font-normal text-neutral-600 group-hover:text-neutral-900"}`}>{label}</span>
                  <input type="radio" className="hidden" name="catalog-price" checked={current.price === id} onChange={() => emit({ ...current, price: id })} />
                </label>
              ))}
            </div>
          </FilterGroup>

        </div>

        {/* Footer */}
        <div className="border-t border-black/10 bg-white px-6 py-5">
          <div className="flex items-center gap-4">
            <button
              className="flex-1 rounded-lg bg-neutral-100 py-3.5 text-[14px] font-medium text-black transition-colors hover:bg-[#d4d4d4] active:scale-[0.98]"
              onClick={() => onReset ? onReset() : emit({ types: [], sizes: [], price: "all" })}
            >
              Đặt lại
            </button>
            <button
              className="flex-2 rounded-lg bg-neutral-900 py-3.5 text-[14px] font-semibold text-white transition-all hover:bg-[#1a1a1a] active:scale-[0.98] disabled:opacity-70"
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
