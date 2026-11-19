"use client";

import { useSearchParams } from "next/navigation";
import { AuthForm } from "@/components/auth-form";

export function LoginPageContent() {
  const searchParams = useSearchParams();
  return <AuthForm mode="login" oauthError={searchParams.get("error") === "google"} />;
}
