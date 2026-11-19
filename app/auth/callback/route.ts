import { NextResponse, type NextRequest } from "next/server";
import { createClient } from "@/lib/supabase/server";

function loginWithError(request: NextRequest) {
  const loginUrl = new URL("/login", request.url);
  loginUrl.searchParams.set("error", "google");
  return NextResponse.redirect(loginUrl);
}

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  if (!code) {
    return loginWithError(request);
  }

  try {
    const supabase = await createClient();
    const { data, error } = await supabase.auth.exchangeCodeForSession(code);
    if (error || !data.user) {
      return loginWithError(request);
    }

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", data.user.id)
      .maybeSingle();

    if (profileError || !profile) {
      return loginWithError(request);
    }

    if (profile.role === "manager" || profile.role === "admin") {
      return NextResponse.redirect(new URL("/admin", request.url));
    }

    if (
      profile.role === "kitchen" ||
      profile.role === "finance" ||
      profile.role === "rider" ||
      profile.role === "support"
    ) {
      return NextResponse.redirect(new URL("/staff", request.url));
    }

    if (profile.role === "customer") {
      return NextResponse.redirect(new URL("/", request.url));
    }
  } catch {
    return loginWithError(request);
  }

  return loginWithError(request);
}
