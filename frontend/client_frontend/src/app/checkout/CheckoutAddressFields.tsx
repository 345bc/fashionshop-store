"use client";

import { useEffect, useState, useRef } from "react";
import { getProvinces, getWards, type AddressOption } from "@/service/addressService";

function SearchableSelect({
  value,
  onChange,
  options,
  placeholder,
  disabled = false,
  loading = false,
  hasError = false
}: {
  value: string | number;
  onChange: (val: string | number) => void;
  options: { value: string | number; label: string }[];
  placeholder: string;
  disabled?: boolean;
  loading?: boolean;
  hasError?: boolean;
}) {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState("");
  const wrapperRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (wrapperRef.current && !wrapperRef.current.contains(event.target as Node)) {
        setIsOpen(false);
        setSearch("");
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const filteredOptions = options.filter(opt => opt.label.toLowerCase().includes(search.toLowerCase()));
  
  const selectedLabel = options.find(o => o.value === value)?.label || "";
  const displayValue = isOpen ? search : selectedLabel;

  return (
    <div ref={wrapperRef} className="relative w-full">
      <div className="relative">
        <input
          type="text"
          disabled={disabled || loading}
          value={displayValue}
          onChange={(e) => {
            setSearch(e.target.value);
            setIsOpen(true);
            if (!e.target.value) onChange(""); // clear if emptied
          }}
          onFocus={() => {
            setIsOpen(true);
            setSearch(""); 
          }}
          placeholder={loading ? "Đang tải..." : placeholder}
          className={`w-full border ${hasError ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : 'border-gray-300 focus:border-black focus:ring-black'} rounded-lg pl-4 pr-10 py-3.5 text-[15px] font-medium text-gray-900 placeholder-gray-500 focus:ring-2 outline-none transition-all text-ellipsis ${disabled || loading ? "bg-gray-100 text-gray-600 cursor-not-allowed disabled:opacity-100" : "bg-white cursor-text"}`}
        />
        <span className="absolute right-3.5 top-1/2 -translate-y-1/2 material-symbols-outlined text-gray-500 pointer-events-none text-[20px]">
          expand_more
        </span>
      </div>

      {isOpen && !disabled && !loading && (
        <ul className="absolute z-10 w-full mt-2 bg-white border border-gray-200 rounded-lg shadow-[0_4px_20px_-4px_rgba(0,0,0,0.1)] max-h-60 overflow-auto py-2">
          {filteredOptions.length > 0 ? (
            filteredOptions.map((opt) => (
              <li
                key={opt.value}
                onClick={() => {
                  onChange(opt.value);
                  setSearch("");
                  setIsOpen(false);
                }}
                className={`px-4 py-2.5 text-[15px] cursor-pointer transition-colors hover:bg-gray-50 ${value === opt.value ? "font-bold bg-gray-50 text-black" : "text-gray-700 font-medium"}`}
              >
                {opt.label}
              </li>
            ))
          ) : (
            <li className="px-4 py-3 text-[14px] text-gray-500 text-center font-medium">Không tìm thấy kết quả</li>
          )}
        </ul>
      )}
    </div>
  );
}

type Props = {
  city: string;
  ward: string;
  onChange: (city: string, ward: string) => void;
  showError?: boolean;
};
type Result = { options?: AddressOption[]; error?: string; attempt: number; provinceCode?: number };
export default function CheckoutAddressFields({ city, ward, onChange, showError }: Props) {
  const [provinceAttempt, setProvinceAttempt] = useState(0);
  const [wardAttempt, setWardAttempt] = useState(0);
  const [provinceResult, setProvinceResult] = useState<Result | null>(null);
  const [wardResult, setWardResult] = useState<Result | null>(null);
  const provinces = provinceResult?.attempt === provinceAttempt ? provinceResult : null;
  const provinceCode = provinces?.options?.find(option => option.name === city)?.code;
  const wards = wardResult?.provinceCode === provinceCode && wardResult?.attempt === wardAttempt ? wardResult : null;

  useEffect(() => {
    const controller = new AbortController();
    getProvinces(controller.signal).then(options => {
      if (!controller.signal.aborted) setProvinceResult({ options, attempt: provinceAttempt });
    }).catch(cause => {
      if (!controller.signal.aborted) setProvinceResult({ error: cause instanceof Error ? cause.message : "Không tải được tỉnh/thành phố", attempt: provinceAttempt });
    });
    return () => controller.abort();
  }, [provinceAttempt]);

  useEffect(() => {
    if (!provinceCode) return;
    const controller = new AbortController();
    getWards(provinceCode, controller.signal).then(options => {
      if (!controller.signal.aborted) setWardResult({ options, provinceCode, attempt: wardAttempt });
    }).catch(cause => {
      if (!controller.signal.aborted) setWardResult({ error: cause instanceof Error ? cause.message : "Không tải được phường/xã", provinceCode, attempt: wardAttempt });
    });
    return () => controller.abort();
  }, [provinceCode, wardAttempt]);

  return <>
    <div id="checkout-address-fields" className="md:col-span-1">
      <label htmlFor="checkout-city" className="sr-only">Tỉnh/Thành phố</label>
      <SearchableSelect
        value={provinceCode ?? ""}
        onChange={val => {
          const province = provinces?.options?.find(option => option.code === Number(val));
          onChange(province?.name ?? "", "");
        }}
        options={(provinces?.options || []).map(opt => ({ value: opt.code, label: opt.name }))}
        placeholder={!provinces ? "Đang tải tỉnh/thành phố..." : "Chọn Tỉnh/Thành phố"}
        disabled={!provinces?.options}
        loading={!provinces}
        hasError={showError && !city}
      />
      {provinces?.error && <p className="text-sm text-gray-600 mt-2" role="alert">{provinces.error} <button type="button" className="underline font-semibold" onClick={() => setProvinceAttempt(value => value + 1)}>Thử lại</button></p>}
      {showError && !city && <p className="text-[13px] text-red-600 mt-1.5" role="alert">Vui lòng chọn tỉnh/thành phố</p>}
    </div>
    <div className="md:col-span-1">
      <label htmlFor="checkout-ward" className="sr-only">Phường/Xã</label>
      <SearchableSelect
        value={ward}
        onChange={val => onChange(city, String(val))}
        options={(wards?.options || []).map(opt => ({ value: opt.name, label: opt.name }))}
        placeholder={!provinceCode ? "Chọn tỉnh/thành phố trước" : !wards ? "Đang tải phường/xã..." : "Chọn Phường/Xã"}
        disabled={!provinceCode || !wards?.options}
        loading={!!provinceCode && !wards}
        hasError={showError && !ward && !!city}
      />
      {wards?.error && <p className="text-sm text-gray-600 mt-2" role="alert">{wards.error} <button type="button" className="underline font-semibold" onClick={() => setWardAttempt(value => value + 1)}>Thử lại</button></p>}
      {showError && !ward && !!city && <p className="text-[13px] text-red-600 mt-1.5" role="alert">Vui lòng chọn phường/xã</p>}
    </div>
  </>;
}
