"use client";

import { Building2, HardHat, UserRound } from "lucide-react";
import { useRouter } from "next/navigation";
import { useStore } from "@/lib/store";
import type { Role } from "@/lib/types";

const roles: { role: Role; label: string; path: string; icon: typeof UserRound }[] = [
  { role: "citizen", label: "Citizen", path: "/citizen", icon: UserRound },
  { role: "worker", label: "Worker", path: "/worker", icon: HardHat },
  { role: "admin", label: "City admin", path: "/dashboard", icon: Building2 },
];

export function RoleSwitcher({ minimal = false }: { minimal?: boolean }) {
  const { currentRole, setRole } = useStore();
  const router = useRouter();
  return (
    <div className={minimal ? "role-switch minimal" : "role-switch"} aria-label="Demo role switcher">
      {roles.map(({ role, label, path, icon: Icon }) => (
        <button key={role} className={currentRole === role ? "active" : ""} onClick={() => { setRole(role); router.push(path); }}>
          <Icon size={16} /><span>{label}</span>
        </button>
      ))}
    </div>
  );
}
