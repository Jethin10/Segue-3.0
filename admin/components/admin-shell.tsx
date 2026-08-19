"use client";

import { AlertTriangle, ClipboardList, LayoutDashboard, LogOut, Menu, Settings, Users, X } from "lucide-react";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useState } from "react";
import { Brand } from "./brand";
import { RoleSwitcher } from "./role-switcher";

const nav = [
  { href: "/dashboard", label: "Overview", icon: LayoutDashboard },
  { href: "/dashboard/work-orders", label: "Work Orders", icon: ClipboardList },
  { href: "/investigations", label: "Investigations", icon: AlertTriangle },
  { href: "/dashboard/workers", label: "Workers", icon: Users },
];

export function AdminShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const [open, setOpen] = useState(false);
  return (
    <main className="admin-page">
      <button className="mobile-menu" onClick={() => setOpen(!open)} aria-label="Toggle menu">{open ? <X /> : <Menu />}</button>
      <aside className={`admin-sidebar ${open ? "open" : ""}`}>
        <Brand />
        <p className="municipality">Indore Municipal Corporation</p>
        <nav>
          {nav.map(({ href, label, icon: Icon }) => {
            const active = href === "/dashboard" ? pathname === href : pathname.startsWith(href);
            return <Link key={href} href={href} className={active ? "active" : ""} onClick={() => setOpen(false)}><Icon /><span>{label}</span></Link>;
          })}
        </nav>
        <div className="sidebar-footer">
          <Link href="/"><Settings /> Demo settings</Link>
          <Link href="/"><LogOut /> Exit admin</Link>
        </div>
      </aside>
      <section className="admin-main">
        <div className="admin-topbar"><RoleSwitcher /></div>
        {children}
      </section>
    </main>
  );
}
