"use client";
import { ArrowLeft, Camera, Check, Clock3, MapPin, ShieldCheck, UserPlus, UserRound } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { toast } from "sonner";
import { AdminShell } from "@/components/admin-shell";
import { EvidenceArt } from "@/components/evidence-art";
import { Status } from "@/components/status";
import { useStore } from "@/lib/store";

export default function AdminWorkOrderDetail() {
  const { id } = useParams<{id:string}>(); const { workOrders, assignWorker } = useStore(); const order = workOrders.find(w => w.id === id);
  if (!order) return <AdminShell><div className="admin-content"><h1>Work order not found</h1></div></AdminShell>;
  const chain = [
    { label:"Citizen report", done:true, detail:new Date(order.createdAt).toLocaleString("en-IN"), icon:MapPin },
    { label:"Assignment", done:!!order.workerId, detail:order.workerName || "Awaiting assignment", icon:UserRound },
    { label:"Proof session", done:!!order.proof, detail:order.proof?.id || "Not started", icon:Clock3 },
    { label:"Location validation", done:!!order.proof?.locationVerified, detail:order.proof ? `${Math.round(order.proof.distanceMeters)}m from task` : "Awaiting proof", icon:MapPin },
    { label:"Identity evidence", done:!!order.proof?.identityCaptured, detail:order.proof ? "Fresh capture recorded" : "Awaiting capture", icon:UserRound },
    { label:"Before / after evidence", done:!!order.proof, detail:order.proof ? "Both captures recorded" : "Awaiting capture", icon:Camera },
    { label:"Citizen verdict", done:!!order.verdict, detail:order.verdict ? (order.verdict.fixed ? "Verified" : `Disputed · ${order.verdict.reason}`) : "Awaiting citizen", icon:ShieldCheck },
  ];
  return <AdminShell><div className="admin-content"><header className="page-heading detail"><div><Link href="/dashboard" className="back-link"><ArrowLeft /> Back to overview</Link><span>{order.id} · {order.category}</span><h1>{order.description}</h1><p><MapPin /> {order.address}</p></div><div className="heading-actions"><Status status={order.status} />{!order.workerId && <button className="assign-button large" onClick={() => { assignWorker(order.id); toast.success("Assigned to Worker 019"); }}><UserPlus /> Assign Worker 019</button>}</div></header><section className="evidence-layout"><div className="chain-panel"><div className="panel-heading"><div><span>Immutable trail</span><h2>Chain of evidence</h2></div></div><div className="evidence-chain">{chain.map(({label,done,detail,icon:Icon}) => <div key={label} className={done ? "done" : "pending"}><span>{done ? <Check /> : <Icon />}</span><div><strong>{label}</strong><small>{detail}</small></div></div>)}</div></div><aside className="proof-panel"><div className="panel-heading"><div><span>Verified record</span><h2>Proof of Service</h2></div>{order.proof && <ShieldCheck />}</div>{order.proof ? <><div className="proof-id"><span>{order.proof.id}</span><strong>{new Date(order.proof.serverTimestamp).toLocaleString("en-IN")}</strong></div><div className="proof-facts"><span><strong>{Math.round(order.proof.distanceMeters)}m</strong> from task</span><span><strong>Valid</strong> challenge</span><span><strong>Captured</strong> identity</span></div><div className="evidence-pair"><div><small>Before</small><EvidenceArt kind="before" src={order.proof.beforeWorkUrl} /></div><div><small>After</small><EvidenceArt kind="after" src={order.proof.afterWorkUrl} /></div></div></> : <div className="empty-proof"><ShieldCheck /><h3>No proof submitted yet</h3><p>The worker cannot complete this task until the backend validates every evidence layer.</p></div>}</aside></section></div></AdminShell>;
}
