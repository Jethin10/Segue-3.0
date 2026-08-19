"use client";

import { ArrowLeft, Camera, Check, Crosshair, MapPin } from "lucide-react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useState } from "react";
import { toast } from "sonner";
import { EvidenceArt } from "@/components/evidence-art";
import { MobileShell } from "@/components/mobile-shell";
import { useStore } from "@/lib/store";
import type { Coordinates } from "@/lib/types";

const categories = ["Garbage", "Road / Pothole", "Streetlight", "Drainage", "Water", "Other"];

export default function ReportIssue() {
  const router = useRouter();
  const { createReport } = useStore();
  const [category, setCategory] = useState("Garbage");
  const [description, setDescription] = useState("");
  const [address, setAddress] = useState("Current location, Ward 8");
  const [coordinates, setCoordinates] = useState<Coordinates | null>(null);
  const [photo, setPhoto] = useState("");
  const [locating, setLocating] = useState(false);
  const [submitting, setSubmitting] = useState(false);

  function locate() {
    setLocating(true);
    if (!navigator.geolocation) { toast.error("Location is not available in this browser."); setLocating(false); return; }
    navigator.geolocation.getCurrentPosition(
      position => { setCoordinates({ lat: position.coords.latitude, lng: position.coords.longitude, accuracy: position.coords.accuracy }); setAddress(`${position.coords.latitude.toFixed(5)}, ${position.coords.longitude.toFixed(5)} · Ward 8`); setLocating(false); toast.success("Current location added"); },
      () => { toast.error("Location permission was denied. Allow access in browser settings and try again."); setLocating(false); },
      { enableHighAccuracy: true, timeout: 10_000 },
    );
  }

  function readPhoto(file?: File) {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => setPhoto(String(reader.result));
    reader.readAsDataURL(file);
  }

  function submit(event: React.FormEvent) {
    event.preventDefault();
    if (!description.trim()) return toast.error("Describe the issue before submitting.");
    if (!coordinates) return toast.error("Add the current location before submitting.");
    if (!photo) return toast.error("Capture a photo of the issue before submitting.");
    setSubmitting(true);
    const id = createReport({ category, description: description.trim(), address, coordinates, citizenPhotoUrl: photo });
    toast.success("Report submitted", { description: `${id} is now visible to the city team.` });
    router.push(`/citizen/work-orders/${id}`);
  }

  return (
    <MobileShell>
      <div className="subpage-heading"><Link href="/citizen" aria-label="Back"><ArrowLeft /></Link><div><span>New civic report</span><h1>Report an issue</h1></div></div>
      <form className="report-form" onSubmit={submit}>
        <label>What needs attention?<select value={category} onChange={e => setCategory(e.target.value)}>{categories.map(item => <option key={item}>{item}</option>)}</select></label>
        <label>Describe the issue<textarea rows={4} value={description} onChange={e => setDescription(e.target.value)} placeholder="What happened? Add a clear landmark or detail." /></label>
        <fieldset><legend>Location</legend><button type="button" className={coordinates ? "location-control success" : "location-control"} onClick={locate}><span>{coordinates ? <Check /> : <Crosshair />}</span><span><strong>{coordinates ? "Location added" : locating ? "Finding your location…" : "Use current location"}</strong><small>{coordinates ? `${Math.round(coordinates.accuracy || 0)}m GPS accuracy · pin can be adjusted` : "Required to create the work-site geofence"}</small></span><MapPin /></button></fieldset>
        <fieldset><legend>Photo evidence</legend><label className="camera-control"><input type="file" accept="image/*" capture="environment" onChange={e => readPhoto(e.target.files?.[0])} /><EvidenceArt kind="citizen" src={photo} label="Issue photo" /><span><Camera /> {photo ? "Retake photo" : "Open camera"}</span></label></fieldset>
        <label>Your note <span className="optional">Optional</span><input placeholder="Name or any additional context" /></label>
        <button className="submit-button" disabled={submitting}>{submitting ? "Submitting…" : "Submit report"}</button>
        <p className="privacy-note"><Check /> Your location is used only for this civic report.</p>
      </form>
    </MobileShell>
  );
}
