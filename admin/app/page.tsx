"use client";

import { ArrowRight, Building2, HardHat, MapPin, ShieldCheck, UserRound } from "lucide-react";
import { useRouter } from "next/navigation";
import { Brand } from "@/components/brand";
import { useStore } from "@/lib/store";
import type { Role } from "@/lib/types";

const roles: { role: Role; title: string; description: string; path: string; icon: typeof UserRound }[] = [
  { role: "citizen", title: "Citizen", description: "Report an issue, follow the work, and verify the proof.", path: "/citizen", icon: UserRound },
  { role: "worker", title: "Field worker", description: "See assignments and submit verified proof of service.", path: "/worker", icon: HardHat },
  { role: "admin", title: "City administrator", description: "Assign work, review evidence, and investigate patterns.", path: "/dashboard", icon: Building2 },
];

export default function Home() {
  const { setRole } = useStore();
  const router = useRouter();
  return (
    <main className="entry-page">
      <header><Brand /></header>
      <section className="entry-hero">
        <div>
          <h1>Report it. Watch it get fixed. <em>See the proof.</em></h1>
          <p>PRAMAAN turns claims of civic work into evidence that citizens can verify and cities can investigate.</p>
          <div className="trust-line"><ShieldCheck /> Hardware-free proof of presence <span /> <MapPin /> Citizen-visible accountability</div>
        </div>
        <div className="role-panel">
          <div className="role-panel-heading"><span>Demo access</span><strong>Choose your experience</strong></div>
          {roles.map(({ role, title, description, path, icon: Icon }) => (
            <button key={role} onClick={() => { setRole(role); router.push(path); }}>
              <span className="role-icon"><Icon /></span><span><strong>{title}</strong><small>{description}</small></span><ArrowRight />
            </button>
          ))}
        </div>
      </section>
      <footer>PRAMAAN प्रमाण <span>Built for trusted, accountable cities.</span></footer>
    </main>
  );
}
