"use client";

import { motion, useReducedMotion } from "motion/react";
import type { ReactNode } from "react";

const fadeUp = {
  hidden: { opacity: 0, y: 16 },
  visible: {
    opacity: 1,
    y: 0,
    transition: { duration: 0.5, ease: "easeOut" as const },
  },
};

const stagger = {
  hidden: {},
  visible: {
    transition: { staggerChildren: 0.09 },
  },
};

export function FadeUp({
  children,
  className,
  delay = 0,
}: Readonly<{ children: ReactNode; className?: string; delay?: number }>) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.div
      animate={shouldReduceMotion ? undefined : "visible"}
      className={className}
      initial={shouldReduceMotion ? false : "hidden"}
      variants={{
        ...fadeUp,
        visible: {
          ...fadeUp.visible,
          transition: { ...fadeUp.visible.transition, delay },
        },
      }}
    >
      {children}
    </motion.div>
  );
}

export function Stagger({
  children,
  className,
}: Readonly<{ children: ReactNode; className?: string }>) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.div
      animate={shouldReduceMotion ? undefined : "visible"}
      className={className}
      initial={shouldReduceMotion ? false : "hidden"}
      variants={stagger}
    >
      {children}
    </motion.div>
  );
}

export function StaggerItem({
  children,
  className,
}: Readonly<{ children: ReactNode; className?: string }>) {
  const shouldReduceMotion = useReducedMotion();

  return (
    <motion.div className={className} variants={shouldReduceMotion ? {} : fadeUp}>
      {children}
    </motion.div>
  );
}
