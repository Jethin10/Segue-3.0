import type { WorkStatus } from "@/lib/types";

export const statusText: Record<WorkStatus, string> = {
  reported: "Reported",
  assigned: "Assigned",
  worker_on_site: "Worker on site",
  proof_submitted: "Awaiting your verification",
  citizen_verified: "Verified",
  citizen_disputed: "Disputed",
};

export function Status({ status }: { status: WorkStatus }) {
  return <span className={`status status-${status}`}>{statusText[status]}</span>;
}
