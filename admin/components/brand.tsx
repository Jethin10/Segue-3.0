import Link from "next/link";

export function Brand({ compact = false }: { compact?: boolean }) {
  return (
    <Link href="/" className="brand" aria-label="PRAMAAN home">
      <span className="brand-name">PRAMAAN <b>प्रमाण</b></span>
      {!compact && <span className="brand-subtitle">Proof, not promises.</span>}
    </Link>
  );
}
