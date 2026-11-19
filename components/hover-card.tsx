"use client";

import { motion, useReducedMotion } from "motion/react";
import type { ReactNode } from "react";
import { cn } from "@/lib/utils";

export function HoverCard({
  children,
  className,
}: Readonly<{ children: ReactNode; className?: string }>) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.div
      className={cn(
        "rounded-xl border border-border bg-card transition-colors hover:border-primary/50",
        className,
      )}
      transition={{ duration: 0.18, ease: "easeOut" }}
      whileHover={
        shouldReduceMotion
          ? undefined
          : {
              y: -3,
              boxShadow: "0 12px 32px rgba(240, 165, 75, 0.12)",
            }
      }
      whileTap={shouldReduceMotion ? undefined : { scale: 0.99 }}
    >
      {children}
    </motion.div>
  );
}
