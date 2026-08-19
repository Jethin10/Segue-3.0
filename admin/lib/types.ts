export type Role = "citizen" | "worker" | "admin";
export type WorkStatus = "reported" | "assigned" | "worker_on_site" | "proof_submitted" | "citizen_verified" | "citizen_disputed";

export interface Coordinates { lat: number; lng: number; accuracy?: number }
export interface TimelineEvent { label: string; at: string; tone?: "success" | "danger" }

export interface Proof {
  id: string;
  workOrderId: string;
  workerId: string;
  distanceMeters: number;
  locationVerified: boolean;
  challengeVerified: boolean;
  identityCaptured: boolean;
  beforeWorkUrl: string;
  afterWorkUrl: string;
  selfieUrl: string;
  serverTimestamp: string;
}

export interface WorkOrder {
  id: string;
  category: string;
  description: string;
  address: string;
  ward: number;
  priority: "Standard" | "Urgent";
  status: WorkStatus;
  citizenId: string;
  citizenName: string;
  workerId?: string;
  workerName?: string;
  coordinates: Coordinates;
  geofenceRadius: number;
  createdAt: string;
  citizenPhotoUrl: string;
  timeline: TimelineEvent[];
  proof?: Proof;
  verdict?: { fixed: boolean; reason?: string; at: string };
}

export interface Investigation {
  id: string;
  title: string;
  hypothesis: string;
  ward: number;
  contract: string;
  riskScore: number;
  confidenceLabel: "Low" | "Medium" | "High";
  potentialExposure: number;
  suspiciousProofs: number;
  completedClaims: number;
  disputeRate: number;
  baselineRate: number;
  affectedWorkOrders: string[];
  evidence: { title: string; detail: string; severity: "high" | "medium" }[];
}

export interface DemoState {
  workOrders: WorkOrder[];
  investigations: Investigation[];
  currentRole: Role;
  lastUpdated: string;
}
