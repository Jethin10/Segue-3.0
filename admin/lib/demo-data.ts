import type { DemoState } from "./types";

const now = new Date();
const minutesAgo = (minutes: number) => new Date(now.getTime() - minutes * 60_000).toISOString();

export const initialState: DemoState = {
  currentRole: "citizen",
  lastUpdated: now.toISOString(),
  workOrders: [
    {
      id: "PRM-1042", category: "Garbage", description: "Overflowing garbage near school", address: "Government School Road, Ward 8", ward: 8,
      priority: "Urgent", status: "assigned", citizenId: "citizen-demo", citizenName: "Neha Sharma", workerId: "worker-019", workerName: "Worker 019",
      coordinates: { lat: 22.7196, lng: 75.8577 }, geofenceRadius: 100, createdAt: minutesAgo(32), citizenPhotoUrl: "",
      timeline: [
        { label: "Reported", at: minutesAgo(32) },
        { label: "Assigned to Worker 019", at: minutesAgo(28) },
      ],
    },
    {
      id: "PRM-1039", category: "Drainage", description: "Blocked storm drain causing waterlogging", address: "Depot Road, Ward 8", ward: 8,
      priority: "Standard", status: "assigned", citizenId: "citizen-2", citizenName: "Arun Patel", workerId: "worker-019", workerName: "Worker 019",
      coordinates: { lat: 22.7412, lng: 75.9069 }, geofenceRadius: 100, createdAt: minutesAgo(180), citizenPhotoUrl: "",
      timeline: [{ label: "Reported", at: minutesAgo(180) }, { label: "Assigned to Worker 019", at: minutesAgo(166) }],
    },
    {
      id: "PRM-1034", category: "Streetlight", description: "Streetlight not working at bus stop", address: "MG Road, Ward 11", ward: 11,
      priority: "Standard", status: "citizen_verified", citizenId: "citizen-3", citizenName: "Saira Khan", workerId: "worker-012", workerName: "Worker 012",
      coordinates: { lat: 22.724, lng: 75.883 }, geofenceRadius: 100, createdAt: minutesAgo(540), citizenPhotoUrl: "",
      timeline: [{ label: "Reported", at: minutesAgo(540) }, { label: "Proof verified by citizen", at: minutesAgo(220), tone: "success" }],
    },
    {
      id: "PRM-1028", category: "Road / Pothole", description: "Deep pothole beside market entrance", address: "Central Market, Ward 7", ward: 7,
      priority: "Urgent", status: "citizen_disputed", citizenId: "citizen-demo", citizenName: "Neha Sharma", workerId: "worker-027", workerName: "Worker 027",
      coordinates: { lat: 22.712, lng: 75.873 }, geofenceRadius: 100, createdAt: minutesAgo(1240), citizenPhotoUrl: "",
      timeline: [{ label: "Reported", at: minutesAgo(1240) }, { label: "Citizen disputed: Not fixed", at: minutesAgo(800), tone: "danger" }],
      verdict: { fixed: false, reason: "Not fixed", at: minutesAgo(800) },
    },
  ],
  investigations: [
    {
      id: "INV-W8-001", title: "Possible organised ghost-work — Ward 8",
      hypothesis: "Evidence suggests a coordinated pattern of location-displaced service proofs and unusually high citizen disputes across the Ward 8 sanitation contract. This requires review; it does not establish wrongdoing.",
      ward: 8, contract: "Sanitation Contract", riskScore: 84, confidenceLabel: "High", potentialExposure: 620000,
      suspiciousProofs: 41, completedClaims: 200, disputeRate: 31, baselineRate: 9,
      affectedWorkOrders: ["PRM-0981", "PRM-0987", "PRM-0994", "PRM-1002", "PRM-1011"],
      evidence: [
        { title: "Repeated geo-displacement", detail: "41 proofs were captured more than 150m from expected work locations.", severity: "high" },
        { title: "Citizen contradiction hotspot", detail: "31% dispute rate compared with the 9% city baseline.", severity: "high" },
        { title: "Implausible proof sequence", detail: "Six sites 4.2km apart were recorded within 20 minutes.", severity: "medium" },
        { title: "Billing mismatch", detail: "200 tasks claimed; only 130 carry valid Proof-of-Service records.", severity: "high" },
      ],
    },
  ],
};
