import { haversineMetres, Point } from "./geo.js";

export interface DetectorProof { id:string; workOrderId:string; workerId:string; ward:number; expected:Point; actual:Point; timestamp:number; citizenDisputed:boolean; costPerTask:number }
export interface Finding { type:string; title:string; hypothesis:string; evidence:Record<string,unknown>; affectedWorkOrders:string[]; affectedWorkers:string[]; ward:number; riskScore:number; confidenceLabel:"Low"|"Medium"|"High"; potentialExposure:number }

export function runDetectors(proofs: DetectorProof[], claimedCompletedTasks: number): Finding[] {
  const findings: Finding[] = [];
  const displaced = proofs.filter(p => haversineMetres(p.expected,p.actual)>150);
  const disputed = proofs.filter(p => p.citizenDisputed);
  const byWorker = new Map<string,DetectorProof[]>(); proofs.forEach(p=>byWorker.set(p.workerId,[...(byWorker.get(p.workerId)||[]),p]));
  const impossible = [...byWorker.values()].flatMap(group => group.sort((a,b)=>a.timestamp-b.timestamp).slice(1).map((current,i)=>{const previous=group[i];const seconds=(current.timestamp-previous.timestamp)/1000;const speed=haversineMetres(previous.actual,current.actual)/(seconds||1);return speed>22?{previous,current,speed}:null}).filter(Boolean));
  const cityDisputeRate = proofs.length ? disputed.length/proofs.length : 0;
  const missing = Math.max(0,claimedCompletedTasks-proofs.length);
  const exposure = missing*(proofs[0]?.costPerTask||0);
  const geoSignal=Math.min(30,displaced.length*2); const travelSignal=Math.min(20,impossible.length*5); const contradictionSignal=proofs.length>=10?Math.min(25,cityDisputeRate*80):0; const mismatchSignal=Math.min(25,missing/Math.max(1,claimedCompletedTasks)*70);
  const score=Math.round(geoSignal+travelSignal+contradictionSignal+mismatchSignal);
  if(score>=35) findings.push({type:"compound_pattern",title:"Possible organised ghost-work",hypothesis:"Evidence suggests repeated geo-displacement, citizen contradiction or billing mismatch. Administrative review is required; this does not establish wrongdoing.",evidence:{displacedProofs:displaced.length,impossibleSequences:impossible.length,citizenDisputeRate:cityDisputeRate,validProofs:proofs.length,claimedCompletedTasks,missingProofCount:missing},affectedWorkOrders:[...new Set([...displaced.map(p=>p.workOrderId),...disputed.map(p=>p.workOrderId)])],affectedWorkers:[...new Set(displaced.map(p=>p.workerId))],ward:proofs[0]?.ward||0,riskScore:score,confidenceLabel:score>=70?"High":score>=50?"Medium":"Low",potentialExposure:exposure});
  return findings;
}
