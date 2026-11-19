"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { AuthStatus } from "@/components/auth-status";
import { ThemeToggle } from "@/components/theme-toggle";
import { cn } from "@/lib/utils";

const navigation = {
  staff: [
    { href: "/staff", label: "Overview" },
    { href: "/staff/kitchen", label: "Kitchen" },
    { href: "/staff/orders", label: "Orders" },
  ],
  admin: [
    { href: "/admin/dashboard", label: "Dashboard" },
    { href: "/admin/menu", label: "Menu" },
  ],
};

export function PortalShell({
  area,
  children,
}: Readonly<{ area: "staff" | "admin"; children: ReactNode }>) {
  const pathname = usePathname();
  const links = navigation[area];
  const title = area === "staff" ? "Staff portal" : "Admin portal";

  return (
    <div className="flex min-h-screen flex-col bg-background md:flex-row">
      <aside className="flex shrink-0 flex-col border-b border-sidebar-border bg-sidebar md:min-h-screen md:w-64 md:border-r md:border-b-0">
        <Link
          className="px-6 py-6 font-display text-2xl font-semibold text-primary"
          href="/"
        >
          Restaurant360
        </Link>
        <nav
          aria-label={`${title} navigation`}
          className="flex flex-wrap gap-2 px-4 pb-4 md:flex-col"
        >
          {links.map(({ href, label }) => {
            const active = pathname === href;
            return (
              <Link
                aria-current={active ? "page" : undefined}
                className={cn(
                  "rounded-lg border-l-2 px-3 py-2.5 text-sm font-medium text-sidebar-foreground/80 transition-colors hover:bg-muted hover:text-sidebar-foreground",
                  active
                    ? "border-primary bg-primary/10 text-primary"
                    : "border-transparent",
                )}
                href={href}
                key={href}
              >
                {label}
              </Link>
            );
          })}
        </nav>
      </aside>
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex min-h-16 flex-wrap items-center justify-between gap-3 border-b border-border bg-background/85 px-5 py-3 backdrop-blur-xl md:px-8">
          <p className="text-sm font-medium text-muted-foreground">{title}</p>
          <div className="flex items-center gap-3">
            <ThemeToggle />
            <AuthStatus />
          </div>
        </header>
        {children}
      </div>
    </div>
  );
}
