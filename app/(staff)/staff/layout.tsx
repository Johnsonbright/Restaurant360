import type { ReactNode } from "react";
import { PortalShell } from "@/components/portal-shell";

export default function StaffLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <PortalShell area="staff">{children}</PortalShell>
  );
}
