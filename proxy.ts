import { NextResponse, type NextRequest } from "next/server";
import { updateSession } from "@/lib/supabase/middleware";

const staffRoles = new Set([
  "kitchen",
  "manager",
  "finance",
  "rider",
  "support",
  "admin",
]);

function redirectWithCookies(
  request: NextRequest,
  response: NextResponse,
  path: string,
) {
  const redirectUrl = request.nextUrl.clone();
  redirectUrl.pathname = path;
  redirectUrl.search = "";
  const redirectResponse = NextResponse.redirect(redirectUrl);
  for (const cookie of response.cookies.getAll()) {
    redirectResponse.cookies.set(cookie);
  }
  return redirectResponse;
}

export async function proxy(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  if (pathname === "/auth/callback") {
    return NextResponse.next();
  }

  const isStaffRoute = pathname === "/staff" || pathname.startsWith("/staff/");
  const isAdminRoute = pathname === "/admin" || pathname.startsWith("/admin/");
  const { response, user, role } = await updateSession(request);

  if (!isStaffRoute && !isAdminRoute) {
    return response;
  }

  if (!user) {
    return redirectWithCookies(request, response, "/login");
  }

  if (isAdminRoute && role !== "admin" && role !== "manager") {
    return redirectWithCookies(request, response, "/unauthorized");
  }

  if (isStaffRoute && !staffRoles.has(role ?? "")) {
    return redirectWithCookies(request, response, "/unauthorized");
  }

  return response;
}

export const config = {
  matcher: [
    "/((?!api|_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)",
  ],
};
