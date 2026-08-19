"use client";

import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { initialState } from "./demo-data";
import { distanceMetres } from "./geo";
import type { Coordinates, DemoState, Role, WorkOrder } from "./types";

const STORAGE_KEY = "pramaan-demo-state-v2";
type NewReport = Pick<WorkOrder, "category" | "description" | "address" | "coordinates" | "citizenPhotoUrl"> & { notes?: string };

interface StoreValue extends DemoState {
  setRole(role: Role): void;
  resetDemo(): void;
  createReport(report: NewReport): string;
  assignWorker(id: string, workerId?: string): void;
  markOnSite(id: string): void;
  submitProof(id: string, coordinates: Coordinates, evidence: { selfieUrl: string; beforeWorkUrl: string; afterWorkUrl: string }): { ok: boolean; distance: number; message: string };
  submitVerdict(id: string, fixed: boolean, reason?: string): void;
}

const StoreContext = createContext<StoreValue | null>(null);

export function StoreProvider({ children }: { children: React.ReactNode }) {
  const [state, setState] = useState<DemoState>(initialState);

  useEffect(() => {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) try { setState(JSON.parse(raw) as DemoState); } catch { localStorage.removeItem(STORAGE_KEY); }
    const onStorage = (event: StorageEvent) => { if (event.key === STORAGE_KEY && event.newValue) setState(JSON.parse(event.newValue)); };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, []);

  useEffect(() => { localStorage.setItem(STORAGE_KEY, JSON.stringify(state)); }, [state]);

  const update = useCallback((recipe: (current: DemoState) => DemoState) => {
    setState(current => ({ ...recipe(current), lastUpdated: new Date().toISOString() }));
  }, []);

  const setRole = useCallback((currentRole: Role) => update(s => ({ ...s, currentRole })), [update]);
  const resetDemo = useCallback(() => setState({ ...initialState, lastUpdated: new Date().toISOString() }), []);

  const createReport = useCallback((report: NewReport) => {
    const id = `PRM-${1043 + Math.floor(Math.random() * 800)}`;
    const createdAt = new Date().toISOString();
    const item: WorkOrder = {
      ...report, id, ward: 8, priority: "Standard", status: "reported", citizenId: "citizen-demo", citizenName: "Neha Sharma",
      geofenceRadius: 100, createdAt, timeline: [{ label: "Reported", at: createdAt }],
    };
    update(s => ({ ...s, workOrders: [item, ...s.workOrders] }));
    return id;
  }, [update]);

  const assignWorker = useCallback((id: string, workerId = "worker-019") => update(s => ({
    ...s,
    workOrders: s.workOrders.map(w => w.id === id ? { ...w, workerId, workerName: "Worker 019", status: "assigned", timeline: [...w.timeline, { label: "Assigned to Worker 019", at: new Date().toISOString() }] } : w),
  })), [update]);

  const markOnSite = useCallback((id: string) => update(s => ({ ...s, workOrders: s.workOrders.map(w => w.id === id ? { ...w, status: "worker_on_site", timeline: [...w.timeline, { label: "Worker reached location", at: new Date().toISOString() }] } : w) })), [update]);

  const submitProof = useCallback((id: string, coordinates: Coordinates, evidence: { selfieUrl: string; beforeWorkUrl: string; afterWorkUrl: string }) => {
    const item = state.workOrders.find(w => w.id === id);
    if (!item) return { ok: false, distance: 0, message: "Work order was not found." };
    const distance = distanceMetres(item.coordinates, coordinates);
    if (distance > item.geofenceRadius) return { ok: false, distance, message: `You are ${distance >= 1000 ? `${(distance / 1000).toFixed(1)} km` : `${Math.round(distance)} m`} from this work site. Move within the ${item.geofenceRadius}m verification radius before continuing.` };
    const submittedAt = new Date().toISOString();
    update(s => ({ ...s, workOrders: s.workOrders.map(w => w.id === id ? {
      ...w, status: "proof_submitted",
      proof: { id: `PF-${crypto.randomUUID().slice(0, 6).toUpperCase()}`, workOrderId: id, workerId: w.workerId ?? "worker-019", distanceMeters: distance, locationVerified: true, challengeVerified: true, identityCaptured: true, ...evidence, serverTimestamp: submittedAt },
      timeline: [...w.timeline, { label: "Proof of Service submitted", at: submittedAt }, { label: "Awaiting citizen verification", at: submittedAt }],
    } : w) }));
    return { ok: true, distance, message: `Location verified — ${Math.round(distance)}m from work site.` };
  }, [state.workOrders, update]);

  const submitVerdict = useCallback((id: string, fixed: boolean, reason?: string) => update(s => ({ ...s, workOrders: s.workOrders.map(w => w.id === id ? { ...w, status: fixed ? "citizen_verified" : "citizen_disputed", verdict: { fixed, reason, at: new Date().toISOString() }, timeline: [...w.timeline, { label: fixed ? "Work verified by citizen" : `Citizen disputed: ${reason || "Not fixed"}`, at: new Date().toISOString(), tone: fixed ? "success" : "danger" }] } : w) })), [update]);

  const value = useMemo(() => ({ ...state, setRole, resetDemo, createReport, assignWorker, markOnSite, submitProof, submitVerdict }), [state, setRole, resetDemo, createReport, assignWorker, markOnSite, submitProof, submitVerdict]);
  return <StoreContext.Provider value={value}>{children}</StoreContext.Provider>;
}

export function useStore() {
  const value = useContext(StoreContext);
  if (!value) throw new Error("useStore must be used inside StoreProvider");
  return value;
}
