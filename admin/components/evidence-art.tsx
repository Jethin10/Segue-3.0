import { Camera, Image as ImageIcon } from "lucide-react";

export function EvidenceArt({ kind = "before", src, label }: { kind?: "before" | "after" | "selfie" | "citizen"; src?: string; label?: string }) {
  if (src) return <div className={`evidence-art ${kind}`}><img src={src} alt={label || `${kind} evidence`} /></div>;
  return (
    <div className={`evidence-art ${kind}`} role="img" aria-label={label || `${kind} evidence placeholder`}>
      {kind === "selfie" ? <Camera /> : <ImageIcon />}
      <span>{label || (kind === "after" ? "After work" : kind === "before" ? "Before work" : "Citizen report")}</span>
    </div>
  );
}
