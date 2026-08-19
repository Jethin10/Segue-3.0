import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'ui.dart';

class WorkerHome extends StatelessWidget {
  const WorkerHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const PramaanHeader(),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('work_orders')
              .where('workerId', isEqualTo: 'worker-019')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return EmptyMessage(
                  message: 'Could not load assignments. ${snapshot.error}');
            }
            if (!snapshot.hasData) return const LoadingList();
            final assignments = snapshot.data!.docs
                .where((doc) => !['citizen_verified', 'citizen_disputed']
                    .contains(doc.data()['status']))
                .toList();
            if (assignments.isEmpty) {
              return const EmptyMessage(
                  message:
                      'No active assignments. New work appears here immediately after an administrator assigns it.');
            }
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Row(children: [
                  const Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('Assigned work',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.w900)),
                        SizedBox(height: 4),
                        Text('Verified service queue',
                            style: TextStyle(color: muted))
                      ])),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                          color: const Color(0xFFE8F7EF),
                          borderRadius: BorderRadius.circular(9)),
                      child: const Row(children: [
                        Icon(Icons.verified_user_outlined,
                            color: verified, size: 16),
                        SizedBox(width: 5),
                        Text('Worker 019',
                            style: TextStyle(
                                color: verified,
                                fontSize: 11,
                                fontWeight: FontWeight.w800))
                      ])),
                ]),
                const SizedBox(height: 20),
                for (final doc in assignments) ...[
                  AssignmentCard(id: doc.id, data: doc.data()),
                  const SizedBox(height: 11),
                ],
              ],
            );
          },
        ),
      );
}

class AssignmentCard extends StatelessWidget {
  const AssignmentCard({super.key, required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkerProofPage(id: id, initialData: data))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('$id · ${data['category'] ?? 'Civic work'}',
                        style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                StatusBadge(status: data['status'] ?? 'assigned')
              ]),
              const SizedBox(height: 9),
              Text(data['description'] ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 13),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    color: saffron, size: 17),
                const SizedBox(width: 5),
                Expanded(
                    child: Text(data['address'] ?? 'Ward ${data['ward'] ?? 8}',
                        style: const TextStyle(color: muted, fontSize: 12))),
                const Icon(Icons.arrow_forward_ios, size: 14)
              ]),
            ]),
          ),
        ),
      );
}

class WorkerProofPage extends StatefulWidget {
  const WorkerProofPage(
      {super.key, required this.id, required this.initialData});
  final String id;
  final Map<String, dynamic> initialData;
  @override
  State<WorkerProofPage> createState() => _WorkerProofPageState();
}

class _WorkerProofPageState extends State<WorkerProofPage> {
  String? sessionId;
  String? challenge;
  DateTime? expiresAt;
  double? distance;
  XFile? selfie;
  XFile? before;
  XFile? after;
  String? rejection;
  bool busy = false;
  bool submitted = false;
  Timer? timer;
  int remainingSeconds = 0;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text),
        backgroundColor: error ? disputed : null,
        duration: Duration(seconds: error ? 6 : 3)));
  }

  void startCountdown(int milliseconds) {
    timer?.cancel();
    expiresAt = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    void tick() {
      if (!mounted || expiresAt == null) return;
      setState(() => remainingSeconds =
          expiresAt!.difference(DateTime.now()).inSeconds.clamp(0, 120));
    }

    tick();
    timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<Position?> currentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      message('Turn on location services before verification.', error: true);
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      message(
          'Precise location permission is required. Enable it in device settings.',
          error: true);
      return null;
    }
    return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 12)));
  }

  Future<void> startVerification() async {
    setState(() {
      busy = true;
      rejection = null;
    });
    try {
      final session = await FirebaseFunctions.instance
          .httpsCallable('startProofSession')
          .call({'workOrderId': widget.id});
      final data = Map<String, dynamic>.from(session.data as Map);
      sessionId = data['proofSessionId'] as String;
      challenge = data['challenge'] as String;
      startCountdown(data['challengeExpiresAt'] as int);
      await verifyLocation();
    } on FirebaseFunctionsException catch (error) {
      message(error.message ?? 'Could not start verification.', error: true);
    } catch (error) {
      message('Could not start verification: $error', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verifyLocation() async {
    if (sessionId == null) return startVerification();
    setState(() {
      busy = true;
      rejection = null;
    });
    try {
      final position = await currentPosition();
      if (position == null) return;
      final result = await FirebaseFunctions.instance
          .httpsCallable('verifyLocation')
          .call({
        'proofSessionId': sessionId,
        'lat': position.latitude,
        'lng': position.longitude,
        'gpsAccuracy': position.accuracy
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      setState(() => distance = (data['distanceMeters'] as num).toDouble());
      message('Location verified — ${distance!.round()}m from work site.');
    } on FirebaseFunctionsException catch (error) {
      setState(() => rejection =
          error.message ?? 'Proof rejected. Move closer to the work site.');
      message(rejection!, error: true);
    } catch (error) {
      message('Location verification failed: $error', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> capture(String kind) async {
    try {
      final value = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice:
              kind == 'selfie' ? CameraDevice.front : CameraDevice.rear,
          imageQuality: 76,
          maxWidth: 1800);
      if (value == null || !mounted) return;
      setState(() {
        if (kind == 'selfie') selfie = value;
        if (kind == 'before') before = value;
        if (kind == 'after') after = value;
      });
    } catch (_) {
      message(
          'Camera access failed. Allow camera permission in device settings.',
          error: true);
    }
  }

  Future<String> upload(XFile file, String name) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = FirebaseStorage.instance
        .ref('proof-evidence/${widget.id}/$uid/$name.jpg');
    await ref.putData(
        await file.readAsBytes(), SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> submit() async {
    if (remainingSeconds <= 0) {
      return message(
          'Challenge expired. Restart verification for a fresh challenge.',
          error: true);
    }
    if ([selfie, before, after].any((file) => file == null)) {
      return message('Selfie, before and after captures are all required.',
          error: true);
    }
    setState(() => busy = true);
    try {
      final urls = await Future.wait([
        upload(selfie!, 'selfie'),
        upload(before!, 'before'),
        upload(after!, 'after')
      ]);
      await FirebaseFunctions.instance.httpsCallable('submitProof').call({
        'proofSessionId': sessionId,
        'challenge': challenge,
        'selfieUrl': urls[0],
        'beforeWorkUrl': urls[1],
        'afterWorkUrl': urls[2]
      });
      timer?.cancel();
      setState(() => submitted = true);
    } on FirebaseFunctionsException catch (error) {
      message(error.message ?? 'Proof submission failed.', error: true);
    } catch (error) {
      message('Proof submission failed: $error', error: true);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.initialData;
    if (submitted) return ProofSuccess(onDone: () => Navigator.pop(context));
    return Scaffold(
      appBar: AppBar(title: Text(widget.id)),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(data['description'] ?? '',
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w900, height: 1.15)),
          const SizedBox(height: 8),
          Text(data['address'] ?? 'Ward ${data['ward'] ?? 8}',
              style: const TextStyle(color: muted)),
          const SizedBox(height: 20),
          const ProofLayer(
              icon: Icons.location_on_outlined,
              title: 'Location',
              detail: 'Server-calculated Haversine distance'),
          const ProofLayer(
              icon: Icons.schedule_outlined,
              title: 'Time',
              detail: 'Trusted server timestamp'),
          const ProofLayer(
              icon: Icons.qr_code_2,
              title: 'Challenge',
              detail: 'Short-lived and one-time use'),
          const ProofLayer(
              icon: Icons.face_outlined,
              title: 'Identity evidence',
              detail: 'Fresh front-camera capture'),
          const ProofLayer(
              icon: Icons.photo_camera_outlined,
              title: 'Before / after',
              detail: 'Fresh work evidence'),
          const SizedBox(height: 12),
          if (sessionId == null)
            FilledButton.icon(
                onPressed: busy ? null : startVerification,
                icon: const Icon(Icons.verified_user_outlined),
                label: Text(busy ? 'Starting…' : 'START VERIFICATION')),
          if (sessionId != null) ...[
            ChallengeCard(challenge: challenge!, seconds: remainingSeconds),
            const SizedBox(height: 11),
            VerificationResult(distance: distance, rejection: rejection),
            if (distance == null) ...[
              const SizedBox(height: 11),
              FilledButton.icon(
                  onPressed: busy ? null : verifyLocation,
                  icon: const Icon(Icons.my_location),
                  label: Text(busy ? 'Checking…' : 'Retry precise location'))
            ],
          ],
          if (distance != null) ...[
            const SizedBox(height: 18),
            const Text('Fresh camera evidence',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            CaptureTile(
                title: 'Identity evidence',
                subtitle: 'Front camera',
                complete: selfie != null,
                onTap: () => capture('selfie')),
            const SizedBox(height: 9),
            CaptureTile(
                title: 'Before work',
                subtitle: 'Show the issue before service',
                complete: before != null,
                onTap: () => capture('before')),
            const SizedBox(height: 9),
            CaptureTile(
                title: 'After work',
                subtitle: 'Show the completed service',
                complete: after != null,
                onTap: () => capture('after')),
            const SizedBox(height: 18),
            FilledButton.icon(
                onPressed: busy ? null : submit,
                style: FilledButton.styleFrom(backgroundColor: verified),
                icon: const Icon(Icons.shield_outlined),
                label:
                    Text(busy ? 'Validating proof…' : 'Submit verified proof')),
          ],
        ],
      ),
    );
  }
}

class ProofLayer extends StatelessWidget {
  const ProofLayer(
      {super.key,
      required this.icon,
      required this.title,
      required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(children: [
        Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: const Color(0xFFFFF0E7),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: saffron, size: 19)),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          Text(detail, style: const TextStyle(color: muted, fontSize: 11))
        ])),
        const Icon(Icons.check, color: verified, size: 18)
      ]));
}

class ChallengeCard extends StatelessWidget {
  const ChallengeCard(
      {super.key, required this.challenge, required this.seconds});
  final String challenge;
  final int seconds;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: navy, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        const Icon(Icons.qr_code_2, color: Colors.white, size: 38),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('ONE-TIME CHALLENGE',
              style: TextStyle(
                  color: Color(0xFFAAC0CF),
                  fontSize: 9,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(challenge,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5))
        ])),
        Text('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
                color: seconds < 20 ? Colors.redAccent : saffron,
                fontWeight: FontWeight.w800))
      ]));
}

class VerificationResult extends StatelessWidget {
  const VerificationResult({super.key, this.distance, this.rejection});
  final double? distance;
  final String? rejection;
  @override
  Widget build(BuildContext context) {
    final ok = distance != null;
    return Card(
        child: ListTile(
            contentPadding: const EdgeInsets.all(14),
            leading: Icon(ok ? Icons.check_circle : Icons.cancel_outlined,
                color: ok ? verified : disputed),
            title: Text(ok ? 'Location verified' : 'Proof rejected',
                style: const TextStyle(fontWeight: FontWeight.w900)),
            subtitle: Text(ok
                ? '${distance!.round()}m from work site'
                : rejection ?? 'Location check is required.')));
  }
}

class CaptureTile extends StatelessWidget {
  const CaptureTile(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.complete,
      required this.onTap});
  final String title;
  final String subtitle;
  final bool complete;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          leading: Icon(
              complete ? Icons.check_circle : Icons.camera_alt_outlined,
              color: complete ? verified : saffron),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 15)));
}

class ProofSuccess extends StatelessWidget {
  const ProofSuccess({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    const verifiedLayers = [
      'Location verified',
      'Challenge verified',
      'Identity evidence',
      'Work evidence',
    ];
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                    color: Color(0xFFE8F7EF), shape: BoxShape.circle),
                child: const Icon(Icons.verified, color: verified, size: 48),
              ),
              const SizedBox(height: 20),
              const Text('PROOF OF SERVICE CREATED',
                  style: TextStyle(
                      color: verified,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              const Text('Awaiting citizen verification',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 25, fontWeight: FontWeight.w900, height: 1.15)),
              const SizedBox(height: 25),
              for (final label in verifiedLayers)
                ListTile(
                  leading: const Icon(Icons.check_circle, color: verified),
                  title: Text(label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              const Spacer(),
              FilledButton(
                  onPressed: onDone,
                  child: const Text('Return to assigned work')),
            ],
          ),
        ),
      ),
    );
  }
}
