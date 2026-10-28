import PasswordRecoveryForm from "@/components/PasswordRecoveryForm";

export const metadata = { title: "Quên mật khẩu | ZELLA", robots: { index: false, follow: false } };

export default function ForgotPasswordPage() {
  return <PasswordRecoveryForm />;
}
