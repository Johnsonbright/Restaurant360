"use client";

import Link from "next/link";
import { motion, useReducedMotion } from "motion/react";
import { buttonVariants } from "@/components/ui/button";
import { cn } from "@/lib/utils";

export function HomeHero({
  hasHeroPhoto,
}: Readonly<{ hasHeroPhoto: boolean }>) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <section className="relative isolate overflow-hidden rounded-xl border border-[#24334F] bg-[#0B1424]">
      <motion.div
        aria-hidden="true"
        className="absolute inset-0 origin-center"
        initial={shouldReduceMotion ? false : { scale: 1.05 }}
        animate={{ scale: 1 }}
        transition={{ duration: shouldReduceMotion ? 0 : 8, ease: "easeOut" }}
        style={{
          backgroundImage: hasHeroPhoto
            ? "url('/images/hero.jpg'), radial-gradient(ellipse at 74% 44%, rgba(240,165,75,0.28), transparent 58%)"
            : "radial-gradient(ellipse at 74% 44%, rgba(240,165,75,0.28), transparent 58%)",
          backgroundPosition: "center, center",
          backgroundSize: "cover, cover",
        }}
      />
      <div aria-hidden="true" className="absolute inset-0 bg-[#0B1424]/45" />
      <div className="relative mx-auto grid min-h-[520px] max-w-7xl items-center gap-12 px-6 py-16 text-[#F4EDE2] md:grid-cols-[1.05fr_0.95fr] md:px-12 lg:px-16">
        <div className="max-w-2xl">
          <p className="mb-5 text-xs font-semibold uppercase tracking-[0.24em] text-[#F0A54B]">
            A place at the table
          </p>
          <h1 className="font-display text-5xl leading-[1.04] tracking-tight sm:text-6xl lg:text-7xl">
            An evening worth slowing down for.
          </h1>
          <p className="mt-6 max-w-xl text-base leading-7 text-[#D3D7DF] sm:text-lg">
            Thoughtful plates, warm light, and room to settle in. Welcome to
            Restaurant360.
          </p>
          <div className="mt-9 flex flex-wrap gap-3">
            <Link
              className={cn(
                buttonVariants({ size: "lg" }),
                "h-12 rounded-lg px-6",
              )}
              href="/menu"
            >
              Order Now
            </Link>
            <Link
              className="inline-flex h-12 items-center justify-center rounded-lg border border-[#A9B4C7]/45 px-6 text-sm font-medium text-[#F4EDE2] transition-colors hover:border-[#F0A54B] hover:text-[#F0A54B]"
              href="/reserve"
            >
              Reserve a Table
            </Link>
          </div>
        </div>
        <div className="hidden min-h-72 items-end justify-end md:flex">
          <p className="max-w-56 border-l border-[#F0A54B] pl-4 text-sm leading-6 text-[#D3D7DF]">
            Unhurried dinners. Shared plates. One more story before you go.
          </p>
        </div>
      </div>
    </section>
  );
}
