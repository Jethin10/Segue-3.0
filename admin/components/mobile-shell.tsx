"use client";

import { Activity, Bell, ClipboardPlus, Home, UserRound } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { Brand } from "./brand";
import { RoleSwitcher } from "./role-switcher";

export function MobileShell({ children, role = "citizen" }: { children: React.ReactNode; role?: "citizen" | "worker" }) {
  const pathname = usePathname();
  return (
    <main className="mobile-page">
      <div className="mobile-frame">
        <header className="mobile-header">
          <Brand />
          <button className="icon-button" aria-label="Notifications"><Bell size={20} /></button>
        </header>
        <div className="mobile-content">{children}</div>
        <nav className="bottom-nav" aria-label="Primary navigation">
          <Link href={role === "citizen" ? "/citizen" : "/worker"} className={pathname === `/${role}` ? "active" : ""}><Home /><span>Home</span></Link>
          <Link href={role === "citizen" ? "/citizen/report" : "/worker"} className={pathname.includes("report") ? "active" : ""}><ClipboardPlus /><span>{role === "citizen" ? "Report" : "Work"}</span></Link>
          <Link href={role === "citizen" ? "/citizen" : "/worker"}><Activity /><span>Activity</span></Link>
          <Link href="/"><UserRound /><span>Profile</span></Link>
        </nav>
      </div>
      <aside className="demo-rail"><p>Presentation mode</p><RoleSwitcher minimal /></aside>
    </main>
  );
}
