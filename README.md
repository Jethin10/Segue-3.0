# PRAMAAN

**Proof, not promises.**

PRAMAAN turns a claim that civic work happened into evidence that can be verified, challenged, and analysed for patterns nobody could see from a checkbox. Citizens report a problem and receive the resulting proof. Field workers create a phone-only Proof-of-Service using server-checked location, a short-lived one-time challenge, identity evidence, and before/after photographs. City teams see the complete evidence chain and transparent, deterministic investigation signals.

> Report it. Watch it get fixed. See the proof.

## What is included

- A polished, responsive Next.js application for citizen, worker, and administrator presentation flows.
- A Flutter citizen/worker application connected to the same Firebase collections and callable functions.
- Firebase Authentication, Firestore, Storage, security rules, indexes, and Cloud Functions.
- Server-side Haversine geofence verification and one-time challenge consumption.
- Immutable-ish Proof-of-Service creation and citizen-only verdict submission.
- Deterministic geo-displacement, impossible-travel, citizen-contradiction, and billing/proof mismatch detection.
- A repeatable synthetic dataset with an automatically reviewable Ward 8 investigation.

## Architecture

```text
mobile/ (Flutter: Citizen + Worker)       admin/ (Next.js: City + responsive demo)
                   \                      /
                    Firebase Authentication
                    Cloud Firestore realtime state
                    Firebase Storage evidence
                    Callable Cloud Functions
                              |
               proof validation + anomaly detectors
```

The client never decides that proof is valid. Cloud Functions calculate distance from coordinates, enforce assignment and state, verify/consume the expiring challenge in a transaction, require all evidence references, and then create the proof. See [docs/architecture.md](docs/architecture.md).

## Technology

- Flutter and Dart, Material 3, Geolocator, Image Picker
- Next.js App Router, React, TypeScript, responsive PWA metadata
- Firebase Auth, Cloud Firestore, Storage, Functions v2
- Deterministic TypeScript anomaly engine

## Repository structure

```text
admin/       Next.js admin dashboard and browser demo clients
mobile/      Flutter citizen and worker application
functions/   Callable verification functions and anomaly detectors
scripts/     Idempotent demo-user and synthetic-data seeding
firebase/    Firestore/Storage rules and indexes
docs/        Architecture and presentation runbook
```

## Demo accounts

The seed script creates these accounts for local/demo projects only:

| Role | Email | Password |
|---|---|---|
| Citizen | `citizen@pramaan.demo` | `PramaanDemo!2026` |
| Worker | `worker@pramaan.demo` | `PramaanDemo!2026` |
| Admin | `admin@pramaan.demo` | `PramaanDemo!2026` |

Change `DEMO_PASSWORD` before seeding any shared environment. Never use these credentials in production.

## Firebase setup

1. Create a Firebase project and enable Email/Password Authentication, Firestore, Storage, and Functions.
2. Install the Firebase CLI and authenticate it.
3. Copy `.firebaserc.example` to `.firebaserc` and replace the project ID.
4. Copy `admin/.env.example` to `admin/.env.local` and add the Firebase web-app values.
5. Set `FIREBASE_PROJECT_ID` and use Application Default Credentials for the seed script:

   ```powershell
   $env:FIREBASE_PROJECT_ID="your-project-id"
   gcloud auth application-default login
   ```

6. Deploy the trusted backend boundary:

   ```bash
   firebase deploy --only firestore:rules,firestore:indexes,storage,functions
   ```

For fully local development, start `firebase emulators:start` and point the web/Flutter Firebase SDKs at the emulator ports in `firebase.json`.

## Environment variables

The Next.js client reads the public Firebase web configuration from `admin/.env.local`:

```text
NEXT_PUBLIC_FIREBASE_API_KEY
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
NEXT_PUBLIC_FIREBASE_PROJECT_ID
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
NEXT_PUBLIC_FIREBASE_APP_ID
NEXT_PUBLIC_DEMO_MODE=true
```

The seed script reads `FIREBASE_PROJECT_ID` and optional `DEMO_PASSWORD`. No service-account key belongs in this repository.

## Install

Node.js 20+ and pnpm are required:

```bash
pnpm install
```

Flutter 3.24+ is required for the native mobile app:

```bash
cd mobile
flutter pub get
flutterfire configure
```

`flutterfire configure` may replace `mobile/lib/firebase_options.dart`. For CI or isolated demo builds, the checked-in options class accepts Firebase values through `--dart-define`.

## Run the Next.js app

```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000). The zero-configuration presentation mode stores real user actions in browser storage and synchronizes them between tabs. It mirrors the server validation rules, while configured Firebase/Flutter flows use the deployed trusted functions.

Production build:

```bash
pnpm build
pnpm start --dir admin
```

## Run Flutter

```bash
cd mobile
flutter run \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_APP_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

Camera and precise-location permissions are requested only at the relevant step. Denial produces a recoverable message rather than a crash.

## Cloud Functions

```bash
pnpm --dir functions build
firebase emulators:start --only auth,firestore,storage,functions
```

Callable functions:

- `startProofSession`
- `verifyLocation`
- `submitProof`
- `submitCitizenVerdict`

The scheduled `detectAnomalies` function evaluates the proof stream hourly. Its raw pattern decisions are deterministic; no language model decides whether an anomaly exists.

## Seed and reset demo data

With Application Default Credentials configured:

```bash
pnpm seed
pnpm --dir scripts reset
```

The dataset creates 200 Ward 8 sanitation proofs with controlled geo-displacement, citizen-dispute, impossible-travel, and billing mismatch signals. It also creates a presentation-ready investigation with structured evidence and potential financial exposure.

The browser presentation dataset is independent and can be reset with **Reset presentation data** at the bottom of `/dashboard`.

## Presentation flow

The exact seven-scene runbook is in [docs/demo.md](docs/demo.md). In short:

```text
Citizen report → Admin assignment → Worker geofence rejection/success
→ Challenge + selfie + before/after → Proof-of-Service
→ Citizen dispute → Ward 8 investigation
```

## Verification

```bash
pnpm typecheck
pnpm build
pnpm --dir functions typecheck
cd mobile && flutter analyze
```

## Known prototype limitations

- Browser presentation mode is intentionally local and tab-synchronized so the pitch works without credentials or network. Use Firebase-backed Flutter clients for cross-device realtime state.
- Identity evidence is a fresh camera capture, not production-grade biometric identity verification or liveness.
- GPS remains vulnerable to sophisticated device compromise; the architecture leaves room for App Check, Play Integrity/DeviceCheck, mock-location flags, motion consistency, and signed device assertions.
- Offline Flutter captures rely on Firestore persistence, but evidence-upload retry UI is minimal.
- Map surfaces are lightweight prototype abstractions rather than a paid map-provider integration.
- Investigations prioritize transparent evidence bundles; they do not determine guilt or automate sanctions.

## Production hardening

Before a city deployment: add App Check and device integrity, signed audit events, liveness/face-matching only with legal basis and worker consent, fine-grained municipality tenancy, KMS/key rotation, rate limiting, evidence malware scanning, retention/deletion rules, accessibility and multilingual testing, offline upload queues, observability, disaster recovery, contractor invoice integration, investigation review/appeal workflow, DPIA/privacy review, worker-union consultation, and independent security testing.

PRAMAAN is civic accountability infrastructure, not worker surveillance. Proof must protect honest workers as strongly as it protects public money.
