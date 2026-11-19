import type { ReactNode } from "react";
import { PortalShell } from "@/components/portal-shell";

export default function AdminLayout({ children }: Readonly<{ children: ReactNode }>) {
  return (
    <PortalShell area="admin">{children}</PortalShell>
  );
}
