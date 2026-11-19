"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { AuthStatus } from "@/components/auth-status";
import { ThemeToggle } from "@/components/theme-toggle";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

const links = [
  { href: "/", label: "Home" },
  { href: "/menu", label: "Menu" },
  { href: "/reserve", label: "Reserve" },
  { href: "/contact", label: "Contact" },
  { href: "/login", label: "Login" },
];

export function SiteHeader() {
  const [scrolled, setScrolled] = useState(false);

  useEffect(() => {
    function updateScrollState() {
      setScrolled(window.scrollY > 20);
    }

    window.addEventListener("scroll", updateScrollState, { passive: true });
    return () => window.removeEventListener("scroll", updateScrollState);
  }, []);

  return (
    <header
      className={cn(
        "sticky top-0 z-50 border-b border-border/70 bg-background/85 backdrop-blur-xl transition-shadow",
        scrolled && "shadow-lg shadow-black/10",
      )}
    >
      <div className="mx-auto flex max-w-7xl flex-wrap items-center justify-between gap-x-8 gap-y-3 px-5 py-4">
        <Link href="/" className="font-display text-2xl font-semibold tracking-tight text-primary">
          Restaurant360
        </Link>
        <nav
          aria-label="Main navigation"
          className="flex w-full flex-wrap items-center gap-x-5 gap-y-3 text-sm md:w-auto"
        >
          {links.map(({ href, label }) => (
            <Link
              key={href}
              href={href}
              className="font-medium text-foreground/85 hover:text-primary"
            >
              {label}
            </Link>
          ))}
          <Link
            href="/menu"
            className={cn(buttonVariants({ size: "sm" }), "h-10 rounded-lg px-5")}
          >
            Order Now
          </Link>
          <ThemeToggle />
          <AuthStatus />
        </nav>
      </div>
    </header>
  );
}
