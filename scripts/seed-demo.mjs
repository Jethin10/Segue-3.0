import { applicationDefault, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";

const projectId = process.env.FIREBASE_PROJECT_ID;
if (!projectId) throw new Error("Set FIREBASE_PROJECT_ID before seeding.");
initializeApp({ credential: applicationDefault(), projectId });
const auth = getAuth(); const db = getFirestore();
const password = process.env.DEMO_PASSWORD || "PramaanDemo!2026";

const users = [
  { email:"citizen@pramaan.demo", name:"Neha Sharma", role:"citizen", phone:"+91 90000 00001", ward:8 },
  { email:"worker@pramaan.demo", name:"Ramesh Yadav", role:"worker", phone:"+91 90000 00019", ward:8, workerId:"worker-019" },
  { email:"admin@pramaan.demo", name:"R. Mehta", role:"admin", phone:"+91 90000 00099", ward:0 },
];

async function upsertUser(record) {
  let user; try { user=await auth.getUserByEmail(record.email); await auth.updateUser(user.uid,{password,displayName:record.name}); } catch { user=await auth.createUser({email:record.email,password,displayName:record.name,emailVerified:true}); }
  await db.doc(`users/${user.uid}`).set({uid:user.uid,...record,createdAt:FieldValue.serverTimestamp()},{merge:true}); return user;
}

async function clearDemo(){for(const name of ["work_orders","proofs","proof_sessions","citizen_verdicts","verification_attempts","investigations","billing_claims"]){const snap=await db.collection(name).where("demo","==",true).get();for(const chunk of Array.from({length:Math.ceil(snap.size/400)},(_,i)=>snap.docs.slice(i*400,(i+1)*400))){const batch=db.batch();chunk.forEach(doc=>batch.delete(doc.ref));await batch.commit();}}}

function jitter(i,scale=.0004){return Math.sin(i*71.31)*scale;}
async function seed(){if(process.argv.includes("--reset"))await clearDemo();const [citizen,worker]=await Promise.all(users.map(upsertUser));const batch=db.batch();const now=Date.now();
  for(let i=0;i<200;i++){const orderRef=db.collection("work_orders").doc(`DEMO-${String(i+1).padStart(3,"0")}`);const proofRef=db.collection("proofs").doc(`DEMO-PF-${String(i+1).padStart(3,"0")}`);const suspicious=i<41;const disputed=i<62;const lat=22.7196+jitter(i,.018);const lng=75.8577+jitter(i+9,.018);const proofLat=lat+(suspicious?.0019:jitter(i,.00012));const proofLng=lng+(suspicious?.0016:jitter(i+2,.00012));const at=Timestamp.fromMillis(now-(200-i)*18*60_000);
    batch.set(orderRef,{demo:true,humanId:`PRM-${900+i}`,citizenId:citizen.uid,workerId:"worker-019",workerName:"Worker 019",category:"Garbage",description:`Ward 8 sanitation service ${i+1}`,coordinates:{lat,lng},geofenceRadius:100,ward:8,status:disputed?"citizen_disputed":"citizen_verified",createdAt:at,proofId:proofRef.id,claimedCost:8857});
    batch.set(proofRef,{demo:true,id:proofRef.id,proofId:`PF-${String(i+1).padStart(6,"0")}`,workOrderId:orderRef.id,citizenId:citizen.uid,workerId:"worker-019",ward:8,expected:{lat,lng},actual:{lat:proofLat,lng:proofLng},timestamp:at.toMillis(),serverTimestamp:at,citizenDisputed:disputed,costPerTask:8857,proofStatus:"valid",locationVerified:true,challengeVerified:true,identityCaptured:true});
  }
  batch.set(db.collection("billing_claims").doc("ward-8-sanitation"),{demo:true,ward:8,contract:"Sanitation Contract",claimedCompletedTasks:270,costPerTask:8857,createdAt:FieldValue.serverTimestamp()});
  batch.set(db.collection("investigations").doc("INV-W8-001"),{demo:true,type:"compound_pattern",title:"Possible organised ghost-work — Ward 8",hypothesis:"Evidence suggests repeated displacement and citizen contradiction across the Ward 8 sanitation contract. Requires review.",ward:8,riskScore:84,confidenceLabel:"High",potentialExposure:620000,affectedWorkOrders:["DEMO-001","DEMO-002","DEMO-003"],createdAt:FieldValue.serverTimestamp()});
  await batch.commit();console.log("PRAMAAN demo seeded: 3 users, 200 work orders, 200 proofs, 1 billing claim and 1 investigation.");}
seed().catch(error=>{console.error(error);process.exitCode=1;});
