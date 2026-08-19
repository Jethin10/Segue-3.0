"use client";

import { AlertCircle, ArrowRight, ClipboardCheck, MapPin, Navigation, ShieldCheck } from "lucide-react";
import Link from "next/link";
import { MobileShell } from "@/components/mobile-shell";
import { Status } from "@/components/status";
import { useStore } from "@/lib/store";

export default function WorkerHome() {
  const { workOrders } = useStore();
  const assigned = workOrders.filter(w => w.workerId === "worker-019" && !["citizen_verified", "citizen_disputed"].includes(w.status));
  return (
    <MobileShell role="worker">
      <section className="worker-intro"><div><p>Field worker</p><h1>Good morning, Ramesh.</h1></div><span className="worker-id"><ShieldCheck /> Worker 019</span></section>
      <section className="shift-summary"><ClipboardCheck /><div><strong>{assigned.length} assigned</strong><span>Today’s verified service queue</span></div><span>Ward 8</span></section>
      <section className="section-block">
        <div className="section-heading"><div><span>Assigned work</span><h2>Ready for service</h2></div></div>
        <div className="work-list">
          {assigned.map((order, index) => <Link className="worker-card" href={`/worker/work-orders/${order.id}`} key={order.id}>
            <div className="worker-card-heading"><div><span>{order.id} · {order.category}</span><h3>{order.description}</h3></div><Status status={order.status} /></div>
            <div className="worker-card-map"><MapPin /><div><strong>{order.address}</strong><span>{index === 0 ? "Distance calculated when opened" : "Pre-seeded distance-check task"}</span></div><ArrowRight /></div>
            <div className="worker-card-meta"><span className={order.priority === "Urgent" ? "urgent" : ""}><AlertCircle /> {order.priority}</span><span><Navigation /> {order.geofenceRadius}m geofence</span></div>
          </Link>)}
        </div>
      </section>
    </MobileShell>
  );
}
