import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'ui.dart';

class CitizenHome extends StatelessWidget {
  const CitizenHome({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: const PramaanHeader(),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ReportIssuePage())),
        icon: const Icon(Icons.add),
        label: const Text('Report an issue'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('work_orders')
            .where('citizenId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return EmptyMessage(
                message: 'Could not load reports. ${snapshot.error}');
          }
          if (!snapshot.hasData) return const LoadingList();
          if (snapshot.data!.docs.isEmpty) {
            return const EmptyMessage(
                message: 'Your reports and their proof will appear here.');
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 24, 18, 100),
            children: [
              const Text('Your city should show its work.',
                  style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.8)),
              const SizedBox(height: 7),
              const Text('Report it. Watch it get fixed. See the proof.',
                  style: TextStyle(color: muted)),
              const SizedBox(height: 25),
              const Text('Recent activity',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              for (final doc in snapshot.data!.docs) ...[
                WorkOrderCard(id: doc.id, data: doc.data()),
                const SizedBox(height: 11),
              ],
            ],
          );
        },
      ),
    );
  }
}

class WorkOrderCard extends StatelessWidget {
  const WorkOrderCard({super.key, required this.id, required this.data});
  final String id;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => CitizenWorkOrder(id: id))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                      child: Text('$id · ${data['category'] ?? 'Civic issue'}',
                          style: const TextStyle(
                              color: muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700))),
                  StatusBadge(status: data['status'] ?? 'reported')
                ]),
                const SizedBox(height: 9),
                Text(data['description'] ?? '',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.25)),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.location_on_outlined,
                      size: 16, color: saffron),
                  const SizedBox(width: 5),
                  Expanded(
                      child: Text(
                          data['address'] ?? 'Ward ${data['ward'] ?? 8}',
                          style: const TextStyle(color: muted, fontSize: 12))),
                  const Icon(Icons.arrow_forward_ios, size: 14)
                ]),
              ],
            ),
          ),
        ),
      );
}

class ReportIssuePage extends StatefulWidget {
  const ReportIssuePage({super.key});
  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final description = TextEditingController();
  final notes = TextEditingController();
  String category = 'Garbage';
  Position? position;
  XFile? photo;
  bool locating = false;
  bool sending = false;

  @override
  void dispose() {
    description.dispose();
    notes.dispose();
    super.dispose();
  }

  void message(String text, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(text), backgroundColor: error ? disputed : null));
  }

  Future<void> locate() async {
    setState(() => locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        message('Turn on location services, then try again.', error: true);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        message(
            'Location permission is required to create the work-site geofence.',
            error: true);
        return;
      }
      final result = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 12)));
      if (mounted) setState(() => position = result);
    } catch (error) {
      message('Could not read location: $error', error: true);
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  Future<void> takePhoto() async {
    try {
      final value = await ImagePicker().pickImage(
          source: ImageSource.camera,
          preferredCameraDevice: CameraDevice.rear,
          imageQuality: 78,
          maxWidth: 1800);
      if (value != null && mounted) setState(() => photo = value);
    } catch (error) {
      message(
          'Camera access failed. Allow camera permission in device settings.',
          error: true);
    }
  }

  Future<void> submit() async {
    if (description.text.trim().isEmpty) {
      return message('Describe the issue before submitting.', error: true);
    }
    if (position == null) {
      return message('Add the current location before submitting.',
          error: true);
    }
    if (photo == null) {
      return message('Capture a photo before submitting.', error: true);
    }
    setState(() => sending = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final id = 'PRM-${1000 + DateTime.now().millisecondsSinceEpoch % 8999}';
      final imageRef =
          FirebaseStorage.instance.ref('citizen-reports/$uid/$id.jpg');
      await imageRef.putData(await photo!.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'));
      final imageUrl = await imageRef.getDownloadURL();
      await FirebaseFirestore.instance.doc('work_orders/$id').set({
        'citizenId': uid,
        'citizenName':
            FirebaseAuth.instance.currentUser!.displayName ?? 'Citizen',
        'category': category,
        'description': description.text.trim(),
        'notes': notes.text.trim(),
        'coordinates': {'lat': position!.latitude, 'lng': position!.longitude},
        'gpsAccuracy': position!.accuracy,
        'address':
            '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)} · Ward 8',
        'imageUrl': imageUrl,
        'status': 'reported',
        'ward': 8,
        'geofenceRadius': 100,
        'createdAt': FieldValue.serverTimestamp(),
      });
      message('Report submitted — $id');
      if (mounted) {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => CitizenWorkOrder(id: id)));
      }
    } catch (error) {
      message('Report could not be submitted: $error', error: true);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Report an issue')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('What needs attention?',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                'Garbage',
                'Road / Pothole',
                'Streetlight',
                'Drainage',
                'Water',
                'Other'
              ]
                  .map((value) =>
                      DropdownMenuItem(value: value, child: Text(value)))
                  .toList(),
              onChanged: (value) => setState(() => category = value!),
            ),
            const SizedBox(height: 14),
            TextField(
                controller: description,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add a clear landmark or useful detail')),
            const SizedBox(height: 14),
            TextField(
                controller: notes,
                decoration: const InputDecoration(
                    labelText: 'Citizen note (optional)')),
            const SizedBox(height: 14),
            EvidenceControl(
                icon: position == null ? Icons.my_location : Icons.check_circle,
                title: position == null
                    ? (locating
                        ? 'Finding your location…'
                        : 'Use current location')
                    : 'Location added',
                subtitle: position == null
                    ? 'Required to create the work-site geofence'
                    : '${position!.accuracy.round()}m GPS accuracy',
                complete: position != null,
                onTap: locating ? null : locate),
            const SizedBox(height: 10),
            EvidenceControl(
                icon: photo == null
                    ? Icons.camera_alt_outlined
                    : Icons.check_circle,
                title: photo == null ? 'Take issue photo' : 'Photo captured',
                subtitle: 'Fresh rear-camera evidence',
                complete: photo != null,
                onTap: takePhoto),
            const SizedBox(height: 22),
            FilledButton(
                onPressed: sending ? null : submit,
                child: Text(sending ? 'Submitting…' : 'Submit report')),
          ],
        ),
      );
}

class EvidenceControl extends StatelessWidget {
  const EvidenceControl(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.complete,
      required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool complete;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
      child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          leading: Icon(icon, color: complete ? verified : saffron),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 15)));
}

class CitizenWorkOrder extends StatelessWidget {
  const CitizenWorkOrder({super.key, required this.id});
  final String id;

  Future<void> verdict(BuildContext context, bool fixed) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('submitCitizenVerdict')
          .call({
        'workOrderId': id,
        'fixed': fixed,
        'reason': fixed ? null : 'Not fixed'
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fixed
                ? 'Thank you — work verified.'
                : 'Dispute recorded for review.')));
      }
    } on FirebaseFunctionsException catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(error.message ?? 'Verdict failed.'),
            backgroundColor: disputed));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(id)),
        body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.doc('work_orders/$id').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.data!.exists) {
              return const EmptyMessage(message: 'Work order not found.');
            }
            final data = snapshot.data!.data()!;
            return ListView(
              padding: const EdgeInsets.all(18),
              children: [
                Text(data['description'] ?? '',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15)),
                const SizedBox(height: 10),
                Align(
                    alignment: Alignment.centerLeft,
                    child: StatusBadge(status: data['status'] ?? 'reported')),
                const SizedBox(height: 22),
                ProgressLine(
                    done: true,
                    title: 'Citizen report recorded',
                    detail: data['address'] ?? 'Ward ${data['ward'] ?? 8}'),
                ProgressLine(
                    done: data['workerId'] != null,
                    title: 'Assignment',
                    detail: data['workerName'] ?? 'Awaiting a field worker'),
                ProgressLine(
                    done: data['proofId'] != null,
                    title: 'Proof of Service',
                    detail: data['proofId'] ?? 'Awaiting verified proof'),
                const SizedBox(height: 18),
                if (data['status'] == 'proof_submitted') ...[
                  const Text('Was this actually fixed?',
                      style:
                          TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 7),
                  const Text(
                      'Your answer is written separately from the original proof.',
                      style: TextStyle(color: muted)),
                  const SizedBox(height: 13),
                  Row(children: [
                    Expanded(
                        child: FilledButton.icon(
                            onPressed: () => verdict(context, true),
                            style: FilledButton.styleFrom(
                                backgroundColor: verified),
                            icon: const Icon(Icons.thumb_up_outlined),
                            label: const Text('YES — Verify'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: FilledButton.icon(
                            onPressed: () => verdict(context, false),
                            style: FilledButton.styleFrom(
                                backgroundColor: disputed),
                            icon: const Icon(Icons.thumb_down_outlined),
                            label: const Text('NO — Dispute'))),
                  ]),
                ],
              ],
            );
          },
        ),
      );
}

class ProgressLine extends StatelessWidget {
  const ProgressLine(
      {super.key,
      required this.done,
      required this.title,
      required this.detail});
  final bool done;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
            color: done ? verified : muted),
        const SizedBox(width: 11),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(detail, style: const TextStyle(color: muted, fontSize: 12))
        ]))
      ]));
}
