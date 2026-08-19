"use client";

import { ArrowLeft, Camera, Check, CheckCircle2, Clock3, Crosshair, MapPin, QrCode, RotateCcw, ShieldCheck, UserRound, XCircle } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { useEffect, useMemo, useState } from "react";
import { toast } from "sonner";
import { EvidenceArt } from "@/components/evidence-art";
import { MobileShell } from "@/components/mobile-shell";
import { Status } from "@/components/status";
import { distanceMetres, formatDistance } from "@/lib/geo";
import { useStore } from "@/lib/store";
import type { Coordinates } from "@/lib/types";

type Step = "overview" | "location" | "evidence" | "review" | "success";

export default function WorkerWorkOrder() {
  const { id } = useParams<{ id: string }>();
  const { workOrders, markOnSite, submitProof } = useStore();
  const order = workOrders.find(item => item.id === id);
  const [step, setStep] = useState<Step>(order?.proof ? "success" : "overview");
  const [coordinates, setCoordinates] = useState<Coordinates | null>(null);
  const [locationResult, setLocationResult] = useState<{ ok: boolean; message: string; distance: number } | null>(null);
  const [expiresAt, setExpiresAt] = useState(() => Date.now() + 120_000);
  const [remaining, setRemaining] = useState(120);
  const [selfie, setSelfie] = useState("");
  const [before, setBefore] = useState("");
  const [after, setAfter] = useState("");
  const currentOrder = order;

  useEffect(() => {
    if (step !== "location" && step !== "evidence") return;
    const timer = window.setInterval(() => setRemaining(Math.max(0, Math.ceil((expiresAt - Date.now()) / 1000))), 1000);
    return () => window.clearInterval(timer);
  }, [step, expiresAt]);

  const challenge = useMemo(() => `PRM-${id.slice(-4)}-${Math.floor(expiresAt / 2000).toString(36).toUpperCase().slice(-4)}`, [expiresAt, id]);
  if (!order) return <MobileShell role="worker"><div className="empty-state"><h2>Assignment not found</h2><Link href="/worker">Return to assignments</Link></div></MobileShell>;

  function start() { setExpiresAt(Date.now() + 120_000); setRemaining(120); setStep("location"); }

  function verifyLocation() {
    if (!navigator.geolocation) return toast.error("Location is not supported on this device.");
    toast.loading("Checking location with the work site…", { id: "location" });
    navigator.geolocation.getCurrentPosition(position => {
      const current = { lat: position.coords.latitude, lng: position.coords.longitude, accuracy: position.coords.accuracy };
      setCoordinates(current);
      if (!currentOrder) return;
      const distance = distanceMetres(currentOrder.coordinates, current);
      const ok = distance <= currentOrder.geofenceRadius;
      const rejection = `You are ${formatDistance(distance)} from this work site. Move within the ${currentOrder.geofenceRadius}m verification radius before continuing.`;
      setLocationResult({ ok, distance, message: ok ? `Location verified — ${formatDistance(distance)} from work site.` : rejection });
      if (ok) { markOnSite(currentOrder.id); toast.success("Location verified", { id: "location", description: `${formatDistance(distance)} from work site.` }); }
      else toast.error("Proof rejected", { id: "location", description: rejection, duration: 7000 });
    }, () => toast.error("Location permission denied", { id: "location", description: "Allow precise location in device settings before continuing." }), { enableHighAccuracy: true, timeout: 10_000 });
  }

  function readFile(file: File | undefined, setter: (value: string) => void) {
    if (!file) return;
    const reader = new FileReader(); reader.onload = () => setter(String(reader.result)); reader.readAsDataURL(file);
  }

  function finalSubmit() {
    if (!coordinates) return toast.error("Location verification is missing.");
    if (remaining <= 0) return toast.error("Challenge expired", { description: "Restart verification to receive a new one-time challenge." });
    if (!selfie || !before || !after) return toast.error("All three camera captures are required.");
    if (!currentOrder) return;
    const result = submitProof(currentOrder.id, coordinates, { selfieUrl: selfie, beforeWorkUrl: before, afterWorkUrl: after });
    if (!result.ok) return toast.error("Proof rejected", { description: result.message });
    setStep("success"); toast.success("Proof of Service created");
  }

  const steps = ["On-site", "Capture", "Review", "Submit"];
  const activeIndex = step === "overview" ? 0 : step === "location" ? 0 : step === "evidence" ? 1 : step === "review" ? 2 : 3;

  return <MobileShell role="worker">
    <div className="subpage-heading"><Link href="/worker" aria-label="Back"><ArrowLeft /></Link><div><span>{order.id} · Assigned work</span><h1>{order.description}</h1></div></div>
    <div className="worker-task-summary"><div><Status status={order.status} /><span>{order.priority} priority</span></div><p><MapPin /> {order.address}</p></div>
    {step === "overview" && <>
      <EvidenceArt kind="citizen" src={order.citizenPhotoUrl} label="Citizen complaint photo" />
      <section className="detail-section"><span className="section-label">Citizen complaint</span><h2>{order.description}</h2><p>Reported by {order.citizenName}. Complete every evidence layer at the work site.</p></section>
      <div className="proof-layers">{[[MapPin,"Location"],[Clock3,"Server time"],[QrCode,"Challenge"],[UserRound,"Identity evidence"],[Camera,"Before / after"]].map(([Icon,label]) => { const I=Icon as typeof MapPin; return <span key={String(label)}><I />{String(label)}<Check /></span>; })}</div>
      <button className="submit-button" onClick={start}>Start verification</button>
    </>}
    {step !== "overview" && <div className="verification-stepper">{steps.map((label,index) => <div key={label} className={index <= activeIndex ? "active" : ""}><span>{index < activeIndex ? <Check /> : index + 1}</span><small>{label}</small></div>)}</div>}
    {step === "location" && <section className="verification-panel">
      <div className="challenge-card"><div><span>One-time rotating challenge</span><strong>{challenge}</strong></div><QrCode /><small className={remaining < 20 ? "danger-text" : ""}>Expires in {Math.floor(remaining / 60)}:{String(remaining % 60).padStart(2,"0")}</small><button onClick={() => { setExpiresAt(Date.now() + 120_000); setRemaining(120); }}><RotateCcw /> Refresh challenge</button></div>
      <div className={`geofence-check ${locationResult ? (locationResult.ok ? "success" : "error") : ""}`}>{locationResult?.ok ? <CheckCircle2 /> : locationResult ? <XCircle /> : <Crosshair />}<div><strong>{locationResult ? (locationResult.ok ? "Location verified" : "Proof rejected") : "Verify your work-site location"}</strong><p>{locationResult?.message || `You must be within the ${order.geofenceRadius}m verification radius.`}</p></div></div>
      {!locationResult?.ok ? <button className="submit-button" onClick={verifyLocation}><Crosshair /> Use precise location</button> : <button className="submit-button" onClick={() => setStep("evidence")}>Continue to evidence</button>}
    </section>}
    {step === "evidence" && <section className="capture-stack">
      <div className="capture-intro"><ShieldCheck /><div><h2>Fresh camera evidence</h2><p>Gallery upload is disabled on supported mobile devices.</p></div></div>
      {([{ key:"selfie", title:"Identity evidence", subtitle:"Front camera · fresh capture", kind:"selfie", value:selfie, setter:setSelfie, capture:"user" },{ key:"before",title:"Before work",subtitle:"Show the issue before service",kind:"before",value:before,setter:setBefore,capture:"environment" },{ key:"after",title:"After work",subtitle:"Show the completed service",kind:"after",value:after,setter:setAfter,capture:"environment" }] as const).map(item => <label className="capture-row" key={item.key}><input type="file" accept="image/*" capture={item.capture} onChange={e => readFile(e.target.files?.[0], item.setter)} /><EvidenceArt kind={item.kind} src={item.value} /><div><strong>{item.title}</strong><span>{item.subtitle}</span></div><span className={item.value ? "captured" : ""}>{item.value ? <Check /> : <Camera />}</span></label>)}
      <button className="submit-button" disabled={!selfie || !before || !after} onClick={() => setStep("review")}>Review proof</button>
    </section>}
    {step === "review" && <section className="review-proof"><div className="review-heading"><ShieldCheck /><div><span>Ready to submit</span><h2>Proof of Service</h2></div></div><div className="proof-facts"><span><strong>{formatDistance(locationResult?.distance || 0)}</strong> task distance</span><span><strong>{remaining}s</strong> challenge left</span><span><strong>3/3</strong> captures</span></div><div className="evidence-trio"><EvidenceArt kind="selfie" src={selfie} /><EvidenceArt kind="before" src={before} /><EvidenceArt kind="after" src={after} /></div><p className="immutability-note"><ShieldCheck /> The backend validates assignment, geofence, challenge and evidence before creating the proof.</p><button className="submit-button" onClick={finalSubmit}>Submit verified proof</button></section>}
    {step === "success" && <section className="proof-success"><span><CheckCircle2 /></span><p>Proof of Service created</p><h1>{order.proof?.id || "Verified proof"}</h1><div>{["Location verified","Challenge verified","Identity evidence","Work evidence"].map(item => <p key={item}><Check /> {item}</p>)}</div><strong>Awaiting citizen verification</strong><Link href="/worker">Return to assigned work</Link></section>}
  </MobileShell>;
}
