"use client";

import { ArrowRight, Clock3, MapPin, Plus, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { MobileShell } from "@/components/mobile-shell";
import { Status } from "@/components/status";
import { useStore } from "@/lib/store";

export default function CitizenHome() {
  const { workOrders } = useStore();
  const mine = workOrders.filter(w => w.citizenId === "citizen-demo");
  return (
    <MobileShell>
      <section className="mobile-intro">
        <p>Good morning, Neha</p>
        <h1>Your city should show its work.</h1>
        <p className="supporting">Report it. Watch it get fixed. See the proof.</p>
        <Link href="/citizen/report" className="primary-action"><Plus /> Report an issue <ArrowRight /></Link>
      </section>
      <section className="section-block">
        <div className="section-heading"><div><span>Your reports</span><h2>Recent activity</h2></div><span>{mine.length} reports</span></div>
        <div className="work-list">
          {mine.length === 0 && <div className="empty-state"><ShieldCheck /><h3>No reports yet</h3><p>When you report an issue, its progress and proof will appear here.</p></div>}
          {mine.map(order => (
            <Link className="work-card" href={`/citizen/work-orders/${order.id}`} key={order.id}>
              <div className="work-card-top"><span className="category-icon">{order.category.charAt(0)}</span><div><span className="eyeline">{order.id} · {order.category}</span><h3>{order.description}</h3></div><ArrowRight /></div>
              <p><MapPin /> {order.address}</p>
              <div className="work-card-footer"><Status status={order.status} /><span><Clock3 /> {new Date(order.createdAt).toLocaleDateString("en-IN", { day: "numeric", month: "short" })}</span></div>
            </Link>
          ))}
        </div>
      </section>
    </MobileShell>
  );
}
