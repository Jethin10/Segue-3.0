"use client";

import { AlertTriangle, ArrowRight, CheckCircle2, CircleDollarSign, ClipboardList, Filter, MapPin, Search, ShieldAlert, UserPlus } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";
import { toast } from "sonner";
import { AdminShell } from "@/components/admin-shell";
import { Status } from "@/components/status";
import { useStore } from "@/lib/store";

export default function Dashboard() {
  const { workOrders, investigations, assignWorker, resetDemo, lastUpdated } = useStore();
  const [query, setQuery] = useState("");
  const [status, setStatus] = useState("all");
  const filtered = useMemo(() => workOrders.filter(order => (status === "all" || order.status === status) && `${order.id} ${order.description} ${order.category} ${order.ward}`.toLowerCase().includes(query.toLowerCase())), [workOrders, query, status]);
  const investigation = investigations[0];
  const verified = workOrders.filter(w => w.status === "citizen_verified").length;
  const disputed = workOrders.filter(w => w.status === "citizen_disputed").length;
  return <AdminShell><div className="admin-content">
    <header className="page-heading"><div><span>Live civic accountability</span><h1>Overview</h1><p>Work orders, proof status and evidence-led investigations.</p></div><div className="live-indicator"><span /> Live · {new Date(lastUpdated).toLocaleTimeString("en-IN", { hour: "2-digit", minute: "2-digit" })}</div></header>
    <section className="metric-row">
      <div><span className="metric-icon blue"><ClipboardList /></span><p>Work orders</p><strong>{workOrders.length.toLocaleString("en-IN")}</strong><small>{workOrders.filter(w => w.status === "reported").length} awaiting assignment</small></div>
      <div><span className="metric-icon green"><CheckCircle2 /></span><p>Verified proofs</p><strong>{verified}</strong><small>Citizen-confirmed service</small></div>
      <div><span className="metric-icon red"><ShieldAlert /></span><p>Citizen disputes</p><strong>{disputed}</strong><small>{workOrders.length ? Math.round(disputed / workOrders.length * 100) : 0}% of current work</small></div>
      <div><span className="metric-icon orange"><CircleDollarSign /></span><p>Potential exposure</p><strong>₹{(investigation.potentialExposure / 100000).toFixed(1)}L</strong><small>Requires administrative review</small></div>
    </section>
    <section className="dashboard-grid">
      <div className="work-table-panel">
        <div className="panel-heading"><div><span>Operations</span><h2>Live work orders</h2></div><Link href="/dashboard/work-orders">View all <ArrowRight /></Link></div>
        <div className="table-tools"><label><Search /><input value={query} onChange={e => setQuery(e.target.value)} placeholder="Search ID, issue or ward" /></label><label><Filter /><select value={status} onChange={e => setStatus(e.target.value)}><option value="all">All statuses</option><option value="reported">Reported</option><option value="assigned">Assigned</option><option value="proof_submitted">Proof submitted</option><option value="citizen_verified">Verified</option><option value="citizen_disputed">Disputed</option></select></label></div>
        <div className="responsive-table"><table><thead><tr><th>Work order</th><th>Ward</th><th>Status</th><th>Assigned to</th><th>Action</th></tr></thead><tbody>{filtered.slice(0,6).map(order => <tr key={order.id}><td><Link href={`/dashboard/work-orders/${order.id}`}><strong>{order.id}</strong><span>{order.description}</span></Link></td><td>Ward {order.ward}</td><td><Status status={order.status} /></td><td>{order.workerName || <span className="muted">Unassigned</span>}</td><td>{order.status === "reported" ? <button className="assign-button" onClick={() => { assignWorker(order.id); toast.success(`${order.id} assigned to Worker 019`); }}><UserPlus /> Assign</button> : <Link className="row-link" href={`/dashboard/work-orders/${order.id}`}>Open <ArrowRight /></Link>}</td></tr>)}</tbody></table></div>
      </div>
      <aside className="investigation-spotlight">
        <div className="risk-label"><AlertTriangle /> High risk · Requires review</div><span>Investigation</span><h2>{investigation.title}</h2><p>{investigation.hypothesis}</p>
        <div className="risk-score"><div><strong>{investigation.riskScore}</strong><span>Risk Score</span></div><div className="score-bar"><span style={{ width: `${investigation.riskScore}%` }} /></div><em>{investigation.confidenceLabel} confidence</em></div>
        <div className="investigation-stats"><span><strong>{investigation.suspiciousProofs}</strong>suspicious proofs</span><span><strong>{investigation.disputeRate}%</strong>citizen dispute rate</span><span><strong>₹{(investigation.potentialExposure/100000).toFixed(1)}L</strong>potential exposure</span></div>
        <div className="mini-map"><div className="ward-shape"><span>8</span></div><p><MapPin /> Geo-displacement cluster · Ward 8</p></div>
        <Link className="submit-button" href={`/investigations/${investigation.id}`}>Open investigation <ArrowRight /></Link>
      </aside>
    </section>
    <button className="reset-demo" onClick={() => { resetDemo(); toast.success("Demo data reset"); }}>Reset presentation data</button>
  </div></AdminShell>;
}
