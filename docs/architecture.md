# PRAMAAN architecture

PRAMAAN is a Firebase-backed civic proof system with two clients and one trusted verification boundary.

```text
Citizen / Worker Flutter app ─┐
                              ├─ Firebase Auth
Next.js admin + mobile PWA ───┼─ Firestore realtime state
                              ├─ Storage evidence objects
                              └─ Callable Cloud Functions
                                     ├─ assignment/session checks
                                     ├─ server-side Haversine geofence
                                     ├─ one-time challenge consumption
                                     ├─ immutable proof creation
                                     └─ deterministic anomaly detectors
```

## Trust boundary

Clients may capture evidence and request transitions. They cannot write proofs, verification attempts, investigations, or citizen-verification status directly. Callable Functions check authentication, role/assignment, work-order state, distance, challenge expiry/consumption, and evidence references in a transaction.

## Primary collections

- `users`: identity and role metadata.
- `work_orders`: complaint, assignment and current workflow state.
- `proof_sessions`: short-lived challenges and backend location result.
- `verification_attempts`: accepted and rejected geofence attempts.
- `proofs`: append-only Proof-of-Service records.
- `citizen_verdicts`: out-of-band citizen confirmation/dispute.
- `billing_claims`: claimed completion totals used by mismatch detection.
- `investigations`: transparent hypotheses and structured evidence.

## Prototype threat model

The prototype blocks direct completion writes, remote check-in beyond the geofence, simple challenge replay, missing evidence, duplicate challenge use, and worker-written citizen verdicts. Production needs App Check, device integrity/mock-location signals, malware-resistant key storage, liveness/face matching where legally appropriate, evidence retention policies, audit exports, KMS-backed signing, rate limits, and an explicit worker privacy/appeal process.
