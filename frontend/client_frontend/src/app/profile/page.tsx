"use client";

import { useCallback, useState, useEffect, useRef } from "react";
import Header from "@/components/Header";
import Footer from "@/components/Footer";
import AccountNav from "@/components/AccountNav";
import styles from "@/components/account/AccountLayout.module.css";
import AccountSessionGuard from "../../components/account/AccountSessionGuard";

import { useAuth } from "@/auth/AuthContext";
import { getIdByUserId, updateProfile } from "../../service/customerApi";
import FieldSuccess from "@/utils/FieldSuccess";
import CheckoutAddressFields from "../checkout/CheckoutAddressFields";

export default function ProfilePage() {
  const [successMsg, setSuccessMsg] = useState<string | null>(null);
  const auth = useAuth();

  const [profileState, setProfileState] = useState<{ status: string; data: Record<string, unknown> | null; error: unknown }>({
    status: "idle",
    data: null,
    error: null,
  });

  const [address, setAddress] = useState({ street: "", city: "", ward: "" });
  const [addressError, setAddressError] = useState("");
  const addressInitialized = useRef(false);

  useEffect(() => {
    if (!addressInitialized.current) {
      const fullAddress = (profileState.data?.address as string) || (auth?.user?.profile?.address as string) || "";
      if (fullAddress || profileState.status === "success") {
        const parts = fullAddress.split(",").map(s => s.trim());
        if (parts.length >= 3) {
          setAddress({
            city: parts[parts.length - 1],
            ward: parts[parts.length - 2],
            street: parts.slice(0, parts.length - 2).join(", ")
          });
        } else {
          setAddress({ street: fullAddress, city: "", ward: "" });
        }
        addressInitialized.current = true;
      }
    }
  }, [profileState, auth?.user]);

  const load = useCallback(async () => {
    if (!auth?.user?.id) return;
    try {
      setProfileState((current) => ({ ...current, status: "loading" }));
      const response = await getIdByUserId(auth.user.id as string);
      setProfileState({ status: "success", data: response.data, error: null });
    } catch (error) {
      setProfileState((current) => ({ ...current, status: "error", error }));
    }
  }, [auth?.user?.id]);

  useEffect(() => {
    load();
  }, [load]);




  return (
    <>
      <Header />
      <AccountSessionGuard key={String(auth.user?.id ?? "anonymous")}>
        <main className="container mx-auto px-5 lg:px-10 py-10 font-sans text-gray-900">
          <div className={styles.shell}>
            {/* Sidebar */}
            <div className={styles.sidebar}>
              <AccountNav active="profile" />
            </div>

            {/* Main Content */}
            <div className={styles.content}>
              <div className="mb-10">
                <h1 className="text-3xl font-bold mb-2">Hồ sơ cá nhân</h1>
              </div>

              <form onSubmit={async (e) => {
                e.preventDefault();
                if (!auth?.user?.id) return;

                if (address.street || address.city || address.ward) {
                  if (!address.city || !address.ward) {
                    setAddressError("Vui lòng chọn tỉnh/thành phố và phường/xã");
                    return;
                  }
                  if (!address.street) {
                    setAddressError("Vui lòng nhập địa chỉ cụ thể");
                    return;
                  }
                }

                const formData = new FormData(e.currentTarget);
                const payload = {
                  fullName: formData.get("fullName") as string,
                  phone: formData.get("phone") as string,
                  address: [address.street, address.ward, address.city].filter(Boolean).join(", "),
                };

                try {
                  setProfileState((current) => ({ ...current, status: "saving" }));
                  await updateProfile(auth.user.id as string, payload);
                  setSuccessMsg("Đã lưu thông tin cá nhân");
                  await load();
                  await auth.refresh();
                } catch (error) {
                  console.error("Failed to update profile", error);
                  alert("Cập nhật thất bại. Vui lòng thử lại.");
                } finally {
                  setProfileState((current) => ({ ...current, status: "success" }));
                }
              }}>
                {/* Thông tin cơ bản */}
                <div className="bg-white border border-zinc-200 rounded-2xl shadow-sm mb-8 transition-shadow hover:shadow-md">
                  <div className="px-6 md:px-8 py-5 border-b border-zinc-100 flex items-center justify-between bg-zinc-50/80 rounded-t-2xl">
                    <div>
                      <h2 className="normal-title">Thông tin cơ bản</h2>
                      <p className="normal-caption">Email dùng để đăng nhập sẽ không thể thay đổi tại đây.</p>
                    </div>
                    <FieldSuccess success={successMsg} />
                  </div>

                  <div className="px-6 md:px-8 py-8 grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-7">
                    <div className="flex flex-col gap-2">
                      <label className="text-[13px] font-bold text-zinc-700">Họ và tên</label>
                      <input
                        name="fullName"
                        className="h-12 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                        defaultValue={(profileState.data?.fullName as string) || (auth?.user?.profile?.fullname as string) || ""}
                        placeholder="Nhập họ và tên..."
                        required
                      />
                    </div>

                    <div className="flex flex-col gap-2">
                      <label className="text-[13px] font-bold text-zinc-700">Số điện thoại</label>
                      <input
                        name="phone"
                        type="tel"
                        pattern="0[0-9]{9}"
                        maxLength={10}
                        title="Số điện thoại phải có 10 chữ số và bắt đầu bằng 0"
                        className="h-12 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                        defaultValue={(profileState.data?.phone as string) || (auth?.user?.profile?.phone as string) || ""}
                        placeholder="Chưa cập nhật"
                      />
                    </div>

                    <div className="flex flex-col gap-2 md:col-span-2">
                      <label className="text-[13px] font-bold text-zinc-700">Email</label>
                      <input
                        className="h-12 px-4 rounded-xl border border-zinc-200 bg-zinc-50 text-[14px] text-zinc-400 font-medium cursor-not-allowed focus:outline-none"
                        defaultValue={(profileState.data?.email as string) || (auth?.user?.email as string) || ""}
                        readOnly
                      />
                    </div>
                  </div>
                </div>

                {/* Địa chỉ mặc định */}
                <div className="bg-white border border-zinc-200 rounded-2xl shadow-sm mb-10 transition-shadow hover:shadow-md">
                  <div className="px-6 md:px-8 py-5 border-b border-zinc-100 bg-zinc-50/80 rounded-t-2xl">
                    <h2 className="normal-title">Địa chỉ mặc định</h2>
                    <p className="normal-caption">Được tự động điền khi bạn thanh toán.</p>
                  </div>

                  <div className="px-6 md:px-8 py-8">
                    <div className="flex flex-col gap-4">
                      <div className="flex flex-col gap-2">
                        <label className="text-[13px] font-bold text-zinc-700">Địa chỉ cụ thể</label>
                        <input
                          type="text"
                          className="h-12 px-4 rounded-xl border border-zinc-300 bg-white text-[14px] text-zinc-900 font-medium focus:outline-none focus:border-black focus:ring-1 focus:ring-black transition-colors"
                          value={address.street}
                          onChange={e => {
                            setAddress({ ...address, street: e.target.value });
                            setAddressError("");
                          }}
                          placeholder="Số nhà, tên đường..."
                        />
                      </div>

                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <CheckoutAddressFields
                          city={address.city}
                          ward={address.ward}
                          onChange={(city, ward) => {
                            setAddress({ ...address, city, ward });
                            if (addressError === "Vui lòng chọn tỉnh/thành phố và phường/xã") setAddressError("");
                          }}
                          showError={addressError === "Vui lòng chọn tỉnh/thành phố và phường/xã"}
                        />
                      </div>
                      {addressError && addressError !== "Vui lòng chọn tỉnh/thành phố và phường/xã" && (
                        <p className="text-red-500 text-sm">{addressError}</p>
                      )}
                    </div>
                  </div>
                </div>

                {/* Nút Submit */}
                <div className="flex justify-end">
                  <button
                    className="h-13 px-10 bg-zinc-900 text-white rounded-full text-[13px] font-bold tracking-wider uppercase hover:bg-black hover:shadow-lg hover:shadow-black/20 transition-all duration-300 active:scale-95 disabled:opacity-50"
                    type="submit"
                    disabled={profileState.status === "saving"}
                  >
                    {profileState.status === "saving" ? "ĐANG LƯU..." : "LƯU THAY ĐỔI"}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </main>
      </AccountSessionGuard>
      <Footer />
    </>
  );
}
