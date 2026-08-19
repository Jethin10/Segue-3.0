import { initializeApp } from "firebase-admin/app";
import { FieldValue, getFirestore } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { randomBytes } from "node:crypto";
import { haversineMetres } from "./geo.js";
import { DetectorProof, runDetectors } from "./detectors.js";

initializeApp(); const db=getFirestore();
const requireAuth=(uid?:string)=>{if(!uid)throw new HttpsError("unauthenticated","Sign in to continue.")};

export const startProofSession=onCall(async request=>{
  requireAuth(request.auth?.uid); const {workOrderId}=request.data as {workOrderId:string};
  const order=await db.doc(`work_orders/${workOrderId}`).get(); if(!order.exists)throw new HttpsError("not-found","Work order not found.");
  const data=order.data()!; const user=await db.doc(`users/${request.auth!.uid}`).get();
  if(data.workerId!==user.data()?.workerId)throw new HttpsError("permission-denied","This work order is not assigned to you.");
  const ref=db.collection("proof_sessions").doc(); const challenge=randomBytes(5).toString("hex").toUpperCase(); const expiresAt=Date.now()+120_000;
  await ref.set({workOrderId,workerId:data.workerId,challenge,challengeExpiresAt:new Date(expiresAt),challengeConsumed:false,createdAt:FieldValue.serverTimestamp()});
  return {proofSessionId:ref.id,challenge,challengeExpiresAt:expiresAt};
});

export const verifyLocation=onCall(async request=>{
  requireAuth(request.auth?.uid); const {proofSessionId,lat,lng,gpsAccuracy}=request.data as {proofSessionId:string;lat:number;lng:number;gpsAccuracy?:number};
  const session=await db.doc(`proof_sessions/${proofSessionId}`).get(); if(!session.exists)throw new HttpsError("not-found","Proof session not found.");
  const order=await db.doc(`work_orders/${session.data()!.workOrderId}`).get(); const data=order.data()!;
  const distance=haversineMetres(data.coordinates,{lat,lng}); const valid=distance<=data.geofenceRadius;
  await db.collection("verification_attempts").add({proofSessionId,workOrderId:order.id,workerId:session.data()!.workerId,lat,lng,gpsAccuracy,distanceMeters:distance,valid,createdAt:FieldValue.serverTimestamp()});
  if(!valid)throw new HttpsError("failed-precondition",`You are ${distance>=1000?(distance/1000).toFixed(1)+" km":Math.round(distance)+" m"} from this work site. Move within the verification radius before continuing.`,{distanceMeters:distance});
  await session.ref.update({locationVerified:true,proofLat:lat,proofLng:lng,gpsAccuracy,distanceMeters:distance}); return {valid:true,distanceMeters:distance};
});

export const submitProof=onCall(async request=>{
  requireAuth(request.auth?.uid); const {proofSessionId,challenge,selfieUrl,beforeWorkUrl,afterWorkUrl}=request.data as Record<string,string>;
  return db.runTransaction(async transaction=>{
    const sessionRef=db.doc(`proof_sessions/${proofSessionId}`); const session=await transaction.get(sessionRef); if(!session.exists)throw new HttpsError("not-found","Proof session not found."); const s=session.data()!;
    if(s.challengeConsumed)throw new HttpsError("failed-precondition","Challenge has already been used."); if(s.challenge!==challenge||s.challengeExpiresAt.toMillis()<Date.now())throw new HttpsError("deadline-exceeded","Challenge expired. Start a fresh verification session."); if(!s.locationVerified)throw new HttpsError("failed-precondition","Backend location verification is required."); if(!selfieUrl||!beforeWorkUrl||!afterWorkUrl)throw new HttpsError("invalid-argument","Selfie, before and after evidence are required.");
    const orderRef=db.doc(`work_orders/${s.workOrderId}`); const order=await transaction.get(orderRef); const o=order.data()!; if(o.workerId!==s.workerId||!["assigned","worker_on_site"].includes(o.status))throw new HttpsError("failed-precondition","Work order is not in a valid state.");
    const proofRef=db.collection("proofs").doc(); const proofId=`PF-${proofRef.id.slice(0,6).toUpperCase()}`;
    transaction.set(proofRef,{proofId,workOrderId:order.id,citizenId:o.citizenId,workerId:s.workerId,expectedLat:o.coordinates.lat,expectedLng:o.coordinates.lng,proofLat:s.proofLat,proofLng:s.proofLng,gpsAccuracy:s.gpsAccuracy,distanceMeters:s.distanceMeters,proofSessionId,challengeVerified:true,identityCaptured:true,selfieUrl,beforeWorkUrl,afterWorkUrl,locationVerified:true,serverTimestamp:FieldValue.serverTimestamp(),proofStatus:"valid"}); transaction.update(sessionRef,{challengeConsumed:true}); transaction.update(orderRef,{status:"proof_submitted",proofId,updatedAt:FieldValue.serverTimestamp()}); return {proofId};
  });
});

export const submitCitizenVerdict=onCall(async request=>{requireAuth(request.auth?.uid);const {workOrderId,fixed,reason}=request.data as {workOrderId:string;fixed:boolean;reason?:string};const orderRef=db.doc(`work_orders/${workOrderId}`);const order=await orderRef.get();if(!order.exists||order.data()!.citizenId!==request.auth!.uid)throw new HttpsError("permission-denied","Only the reporting citizen can submit this verdict.");if(order.data()!.status!=="proof_submitted")throw new HttpsError("failed-precondition","A valid proof is required before a verdict.");await db.runTransaction(async tx=>{tx.set(db.collection("citizen_verdicts").doc(),{workOrderId,citizenId:request.auth!.uid,fixed,reason:reason||null,createdAt:FieldValue.serverTimestamp()});tx.update(orderRef,{status:fixed?"citizen_verified":"citizen_disputed",updatedAt:FieldValue.serverTimestamp()});});return {status:fixed?"citizen_verified":"citizen_disputed"};});

export const detectAnomalies=onSchedule("every 60 minutes",async()=>{const [proofSnap,claimsSnap]=await Promise.all([db.collection("proofs").where("proofStatus","==","valid").get(),db.collection("billing_claims").get()]);const proofs=proofSnap.docs.map(d=>d.data() as unknown as DetectorProof);const claimed=claimsSnap.docs.reduce((sum,d)=>sum+(d.data().claimedCompletedTasks||0),0);const findings=runDetectors(proofs,claimed);for(const finding of findings)await db.collection("investigations").add({...finding,createdAt:FieldValue.serverTimestamp()});});

export { haversineMetres, runDetectors };
