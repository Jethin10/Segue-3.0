"use client";
import { ArrowRight, ClipboardList } from "lucide-react";
import Link from "next/link";
import { AdminShell } from "@/components/admin-shell";
import { Status } from "@/components/status";
import { useStore } from "@/lib/store";

export default function WorkOrdersPage() {
  const { workOrders } = useStore();
  return <AdminShell><div className="admin-content"><header className="page-heading"><div><span>Operations</span><h1>Work Orders</h1><p>Search, assign and inspect the full chain of civic evidence.</p></div></header><section className="work-table-panel full"><div className="panel-heading"><div><ClipboardList /><h2>All work orders</h2></div><span>{workOrders.length} total</span></div><div className="responsive-table"><table><thead><tr><th>Work order</th><th>Category</th><th>Ward</th><th>Status</th><th>Assigned to</th><th /></tr></thead><tbody>{workOrders.map(order => <tr key={order.id}><td><strong>{order.id}</strong><span>{order.description}</span></td><td>{order.category}</td><td>Ward {order.ward}</td><td><Status status={order.status} /></td><td>{order.workerName || "Unassigned"}</td><td><Link className="row-link" href={`/dashboard/work-orders/${order.id}`}>Open <ArrowRight /></Link></td></tr>)}</tbody></table></div></section></div></AdminShell>;
}
