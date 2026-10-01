"use client";


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
}

const typeOptions = ["Áo", "Váy & đầm", "Quần", "Áo khoác", "Phụ kiện"];
const sizeOptions = ["XS", "S", "M", "L", "XL", "XXL"];
const priceOptions = [
  ["all", "Tất cả mức giá"],
  ["under300", "Dưới 300.000₫"],
  ["300to500", "300.000₫ – 500.000₫"],
  ["over500", "Trên 500.000₫"],
];

export default function FilterSidebar({ isOpen, onClose, value, onChange, resultCount = 0 }: FilterSidebarProps) {
  const current = value ?? { types: [], sizes: [], price: "all" };
  const emit = (next: FilterState) => onChange?.(next);
  const toggleArray = (key: "types" | "sizes", item: string) => {
    const exists = current[key].includes(item);
    emit({ ...current, [key]: exists ? current[key].filter((x) => x !== item) : [...current[key], item] });
  };

  return (
    <>
      <div className={`filter-sidebar-overlay ${isOpen ? "show" : ""}`} onClick={onClose} />
      <aside className={`filter-sidebar modern-filter-drawer ${isOpen ? "open" : ""}`} aria-hidden={!isOpen}>
        <div className="filter-sidebar-header modern-filter-head">
          <div>
            <small>TINH CHỈNH KẾT QUẢ</small>
            <h2>Bộ lọc</h2>
          </div>
          <button className="close-sidebar-btn" onClick={onClose} aria-label="Đóng bộ lọc"><span className="material-symbols-outlined" style={{ fontSize: 22 }}>close</span></button>
        </div>

        <div className="modern-filter-body">
          <section className="filter-block">
            <div className="filter-block-title"><span>Loại sản phẩm</span><small>{current.types.length || ""}</small></div>
            <div className="filter-check-list">
              {typeOptions.map((item) => (
                <label key={item}>
                  <input type="checkbox" checked={current.types.includes(item)} onChange={() => toggleArray("types", item)} />
                  <span>{item}</span>
                </label>
              ))}
            </div>
          </section>

          <section className="filter-block">
            <div className="filter-block-title"><span>Kích cỡ</span><small>{current.sizes.length || ""}</small></div>
            <div className="size-filter-grid">
              {sizeOptions.map((item) => (
                <button key={item} className={current.sizes.includes(item) ? "active" : ""} onClick={() => toggleArray("sizes", item)}>{item}</button>
              ))}
            </div>
          </section>

          <section className="filter-block">
            <div className="filter-block-title"><span>Giá</span></div>
            <div className="filter-radio-list">
              {priceOptions.map(([id, label]) => (
                <label key={id}>
                  <input type="radio" name="catalog-price" checked={current.price === id} onChange={() => emit({ ...current, price: id })} />
                  <span>{label}</span>
                </label>
              ))}
            </div>
          </section>
        </div>

        <div className="filter-sidebar-footer modern-filter-footer">
          <button className="filter-reset" onClick={() => emit({ types: [], sizes: [], price: "all" })}>Đặt lại</button>
          <button className="btn-view-products" onClick={onClose}>Xem {resultCount} sản phẩm</button>
        </div>
      </aside>
    </>
  );
}
