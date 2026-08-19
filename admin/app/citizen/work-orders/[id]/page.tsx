"use client";

import { ArrowLeft, CheckCircle2, Clock3, MapPin, ShieldCheck, UserRound, XCircle } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";
import { EvidenceArt } from "@/components/evidence-art";
import { MobileShell } from "@/components/mobile-shell";
import { Status } from "@/components/status";
import { useStore } from "@/lib/store";

const reasons = ["Not fixed", "Partially fixed", "Wrong work", "Photo does not match", "Other"];

export default function CitizenWorkOrder() {
  const { id } = useParams<{ id: string }>();
  const { workOrders, submitVerdict } = useStore();
  const order = workOrders.find(item => item.id === id);
  const [showReasons, setShowReasons] = useState(false);
  const [reason, setReason] = useState("Not fixed");
  if (!order) return <MobileShell><div className="empty-state"><h2>Work order not found</h2><Link href="/citizen">Return home</Link></div></MobileShell>;

  function verdict(fixed: boolean) {
    submitVerdict(order!.id, fixed, fixed ? undefined : reason);
    toast.success(fixed ? "Thank you — work verified" : "Dispute recorded", { description: fixed ? "The city has received your confirmation." : "The evidence remains unchanged and an administrator has been notified." });
    setShowReasons(false);
  }

  return (
    <MobileShell>
      <div className="subpage-heading"><Link href="/citizen" aria-label="Back"><ArrowLeft /></Link><div><span>{order.id} · {order.category}</span><h1>{order.description}</h1></div></div>
      <div className="detail-status"><Status status={order.status} /><span><Clock3 /> Updated {new Date(order.timeline.at(-1)?.at || order.createdAt).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}</span></div>
      <EvidenceArt kind="citizen" src={order.citizenPhotoUrl} label="Original citizen report" />
      <div className="location-summary"><MapPin /><div><strong>{order.address}</strong><span>{order.coordinates.lat.toFixed(5)}, {order.coordinates.lng.toFixed(5)}</span></div><span>Ward {order.ward}</span></div>
      <section className="detail-section"><h2>Progress</h2><div className="timeline">{order.timeline.map((event, index) => <div key={`${event.at}-${index}`} className={event.tone || ""}><span /><div><strong>{event.label}</strong><small>{new Date(event.at).toLocaleString("en-IN", { hour: "2-digit", minute: "2-digit", day: "numeric", month: "short" })}</small></div></div>)}</div></section>
      {order.workerName && <section className="assigned-person"><span><UserRound /></span><div><small>Assigned field worker</small><strong>{order.workerName}</strong></div><ShieldCheck /></section>}
      {order.proof && <section className="proof-receipt">
        <div className="proof-title"><span><CheckCircle2 /></span><div><small>Proof of Service</small><h2>{order.proof.id}</h2></div><ShieldCheck /></div>
        <div className="proof-facts"><span><strong>{Math.round(order.proof.distanceMeters)}m</strong> from task</span><span><strong>{new Date(order.proof.serverTimestamp).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}</strong> server time</span><span><strong>Captured</strong> identity</span></div>
        <div className="evidence-pair"><div><small>Before work</small><EvidenceArt kind="before" src={order.proof.beforeWorkUrl} /></div><div><small>After work</small><EvidenceArt kind="after" src={order.proof.afterWorkUrl} /></div></div>
        {!order.verdict ? <div className="verdict-box"><h3>Was this actually fixed?</h3><p>Your answer closes the accountability loop.</p><div><button className="yes" onClick={() => verdict(true)}><CheckCircle2 /> YES — Verify work</button><button className="no" onClick={() => setShowReasons(true)}><XCircle /> NO — Dispute work</button></div>{showReasons && <div className="reason-box"><label>What went wrong?<select value={reason} onChange={e => setReason(e.target.value)}>{reasons.map(item => <option key={item}>{item}</option>)}</select></label><button className="submit-button danger" onClick={() => verdict(false)}>Submit dispute</button></div>}</div> : <div className={`verdict-complete ${order.verdict.fixed ? "verified" : "disputed"}`}>{order.verdict.fixed ? <CheckCircle2 /> : <XCircle />}<div><strong>{order.verdict.fixed ? "You verified this work" : "You disputed this work"}</strong><span>{order.verdict.reason || "The city has received your confirmation."}</span></div></div>}
      </section>}
    </MobileShell>
  );
}
