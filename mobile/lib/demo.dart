import 'package:flutter/material.dart';

import 'ui.dart';

class DemoOrder {
  DemoOrder({
    required this.id,
    required this.category,
    required this.description,
    required this.address,
    required this.status,
  });

  final String id;
  final String category;
  final String description;
  final String address;
  String status;
}

class DemoStore {
  DemoStore._();
  static final DemoStore instance = DemoStore._();

  final orders = <DemoOrder>[
    DemoOrder(
      id: 'STY-1042',
      category: 'Garbage',
      description: 'Overflowing garbage near school',
      address: 'Government School Road, Ward 8',
      status: 'assigned',
    ),
    DemoOrder(
      id: 'STY-1028',
      category: 'Road / Pothole',
      description: 'Deep pothole beside market entrance',
      address: 'Central Market, Ward 7',
      status: 'citizen_disputed',
    ),
  ];
}

class DemoRoleChooser extends StatelessWidget {
  const DemoRoleChooser({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: navy,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const BrandLockup(),
                const SizedBox(height: 44),
                const Text('Offline demo ready',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 27,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 9),
                const Text(
                    'No sign-in, Firebase project or internet connection is needed. Choose a role and start the prototype.',
                    style: TextStyle(color: Color(0xFFB8CAD6), height: 1.5)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  key: const Key('citizen-demo'),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DemoCitizenHome())),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Continue as citizen'),
                ),
                const SizedBox(height: 11),
                FilledButton.icon(
                  key: const Key('worker-demo'),
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: ink),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DemoWorkerHome())),
                  icon: const Icon(Icons.engineering_outlined),
                  label: const Text('Continue as field worker'),
                ),
                const SizedBox(height: 18),
                const Row(children: [
                  Icon(Icons.offline_bolt, color: verified, size: 18),
                  SizedBox(width: 7),
                  Text('Seeded presentation data included',
                      style: TextStyle(color: Colors.white70, fontSize: 12))
                ]),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
}

PreferredSizeWidget demoHeader(BuildContext context, String role) => AppBar(
      backgroundColor: navy,
      toolbarHeight: 78,
      title: const BrandLockup(),
      actions: [
        Center(
            child: Text(role,
                style: const TextStyle(
                    color: Color(0xFFB8CAD6),
                    fontSize: 11,
                    fontWeight: FontWeight.w700))),
        IconButton(
            tooltip: 'Change demo role',
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.swap_horiz, color: Colors.white)),
        const SizedBox(width: 6),
      ],
    );

class DemoCitizenHome extends StatefulWidget {
  const DemoCitizenHome({super.key});
  @override
  State<DemoCitizenHome> createState() => _DemoCitizenHomeState();
}

class _DemoCitizenHomeState extends State<DemoCitizenHome> {
  @override
  Widget build(BuildContext context) {
    final orders = DemoStore.instance.orders;
    return Scaffold(
      appBar: demoHeader(context, 'CITIZEN DEMO'),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('report-issue'),
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const DemoReportIssue()));
          if (mounted) setState(() {});
        },
        icon: const Icon(Icons.add),
        label: const Text('Report an issue'),
      ),
      body: ListView(
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
          for (final order in orders) ...[
            DemoOrderCard(
              order: order,
              onTap: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DemoCitizenOrder(order: order)));
                if (mounted) setState(() {});
              },
            ),
            const SizedBox(height: 11),
          ],
        ],
      ),
    );
  }
}

class DemoOrderCard extends StatelessWidget {
  const DemoOrderCard({super.key, required this.order, required this.onTap});
  final DemoOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('${order.id} · ${order.category}',
                        style: const TextStyle(
                            color: muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700))),
                StatusBadge(status: order.status),
              ]),
              const SizedBox(height: 9),
              Text(order.description,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: saffron),
                const SizedBox(width: 5),
                Expanded(
                    child: Text(order.address,
                        style: const TextStyle(color: muted, fontSize: 12))),
                const Icon(Icons.arrow_forward_ios, size: 14),
              ])
            ]),
          ),
        ),
      );
}

class DemoReportIssue extends StatefulWidget {
  const DemoReportIssue({super.key});
  @override
  State<DemoReportIssue> createState() => _DemoReportIssueState();
}

class _DemoReportIssueState extends State<DemoReportIssue> {
  final description = TextEditingController();
  String category = 'Garbage';
  bool location = false;
  bool photo = false;

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  void submit() {
    if (description.text.trim().isEmpty || !location || !photo) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Add a description, demo location and demo photo.')));
      return;
    }
    final order = DemoOrder(
      id: 'STY-${1100 + DemoStore.instance.orders.length}',
      category: category,
      description: description.text.trim(),
      address: 'Demo GPS · Ward 8',
      status: 'reported',
    );
    DemoStore.instance.orders.insert(0, order);
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => DemoCitizenOrder(order: order)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Report an issue')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          const Text('What needs attention?',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: ['Garbage', 'Road / Pothole', 'Streetlight', 'Drainage']
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() => category = value!),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('issue-description'),
            controller: description,
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add a clear landmark or useful detail'),
          ),
          const SizedBox(height: 14),
          DemoEvidenceTile(
            key: const Key('demo-location'),
            icon: Icons.my_location,
            title: location ? 'Demo location added' : 'Use demo location',
            subtitle: 'No device permission required',
            complete: location,
            onTap: () => setState(() => location = true),
          ),
          const SizedBox(height: 10),
          DemoEvidenceTile(
            key: const Key('demo-photo'),
            icon: Icons.camera_alt_outlined,
            title: photo ? 'Demo photo attached' : 'Attach demo photo',
            subtitle: 'Presentation-safe sample evidence',
            complete: photo,
            onTap: () => setState(() => photo = true),
          ),
          const SizedBox(height: 22),
          FilledButton(
              key: const Key('submit-report'),
              onPressed: submit,
              child: const Text('Submit demo report')),
        ]),
      );
}

class DemoEvidenceTile extends StatelessWidget {
  const DemoEvidenceTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.complete,
    required this.onTap,
  });
  final IconData icon;
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
          leading: Icon(complete ? Icons.check_circle : icon,
              color: complete ? verified : saffron),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 15),
        ),
      );
}

class DemoCitizenOrder extends StatefulWidget {
  const DemoCitizenOrder({super.key, required this.order});
  final DemoOrder order;
  @override
  State<DemoCitizenOrder> createState() => _DemoCitizenOrderState();
}

class _DemoCitizenOrderState extends State<DemoCitizenOrder> {
  void verdict(bool fixed) {
    setState(() =>
        widget.order.status = fixed ? 'citizen_verified' : 'citizen_disputed');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(fixed
            ? 'Thank you — work verified.'
            : 'Dispute recorded for review.')));
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      appBar: AppBar(title: Text(order.id)),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text(order.description,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.w900, height: 1.15)),
        const SizedBox(height: 10),
        Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge(status: order.status)),
        const SizedBox(height: 22),
        const DemoProgress(done: true, title: 'Citizen report recorded'),
        DemoProgress(
            done: order.status != 'reported',
            title: 'Assigned to field worker'),
        DemoProgress(
            done: order.status == 'proof_submitted' ||
                order.status == 'citizen_verified' ||
                order.status == 'citizen_disputed',
            title: 'Proof of Service'),
        if (order.status == 'proof_submitted') ...[
          const SizedBox(height: 12),
          const Text('Was this actually fixed?',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: () => verdict(true),
              style: FilledButton.styleFrom(backgroundColor: verified),
              icon: const Icon(Icons.thumb_up_outlined),
              label: const Text('YES — Verify')),
          const SizedBox(height: 9),
          FilledButton.icon(
              onPressed: () => verdict(false),
              style: FilledButton.styleFrom(backgroundColor: disputed),
              icon: const Icon(Icons.thumb_down_outlined),
              label: const Text('NO — Dispute')),
        ]
      ]),
    );
  }
}

class DemoProgress extends StatelessWidget {
  const DemoProgress({super.key, required this.done, required this.title});
  final bool done;
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(children: [
          Icon(done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? verified : muted),
          const SizedBox(width: 11),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );
}

class DemoWorkerHome extends StatefulWidget {
  const DemoWorkerHome({super.key});
  @override
  State<DemoWorkerHome> createState() => _DemoWorkerHomeState();
}

class _DemoWorkerHomeState extends State<DemoWorkerHome> {
  @override
  Widget build(BuildContext context) {
    final active = DemoStore.instance.orders
        .where((order) =>
            order.status == 'assigned' || order.status == 'proof_submitted')
        .toList();
    return Scaffold(
      appBar: demoHeader(context, 'WORKER DEMO'),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('Assigned work',
            style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        const Text('Worker 019 · demo evidence mode',
            style: TextStyle(color: muted)),
        const SizedBox(height: 20),
        for (final order in active) ...[
          DemoOrderCard(
            order: order,
            onTap: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => DemoWorkerProof(order: order)));
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 11),
        ]
      ]),
    );
  }
}

class DemoWorkerProof extends StatefulWidget {
  const DemoWorkerProof({super.key, required this.order});
  final DemoOrder order;
  @override
  State<DemoWorkerProof> createState() => _DemoWorkerProofState();
}

class _DemoWorkerProofState extends State<DemoWorkerProof> {
  bool started = false;
  bool selfie = false;
  bool before = false;
  bool after = false;
  bool submitted = false;

  @override
  Widget build(BuildContext context) {
    if (submitted) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(children: [
              const Spacer(),
              const Icon(Icons.verified, color: verified, size: 84),
              const SizedBox(height: 18),
              const Text('PROOF OF SERVICE CREATED',
                  style: TextStyle(
                      color: verified,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1)),
              const SizedBox(height: 8),
              const Text('Awaiting citizen verification',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
              const Spacer(),
              FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Return to assigned work'))
            ]),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(widget.order.id)),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        Text(widget.order.description,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 7),
        Text(widget.order.address, style: const TextStyle(color: muted)),
        const SizedBox(height: 20),
        const DemoProgress(done: true, title: 'Server location check'),
        const DemoProgress(done: true, title: 'One-time challenge'),
        const DemoProgress(done: true, title: 'Identity evidence'),
        const DemoProgress(done: true, title: 'Before / after evidence'),
        const SizedBox(height: 10),
        if (!started)
          FilledButton.icon(
              key: const Key('start-verification'),
              onPressed: () => setState(() => started = true),
              icon: const Icon(Icons.verified_user_outlined),
              label: const Text('START DEMO VERIFICATION')),
        if (started) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: navy, borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.qr_code_2, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                  child: Text('SATYAK-8F2A · location verified',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800))),
              Icon(Icons.check_circle, color: verified),
            ]),
          ),
          const SizedBox(height: 14),
          DemoEvidenceTile(
              key: const Key('demo-selfie'),
              title: selfie ? 'Identity captured' : 'Capture demo identity',
              subtitle: 'No camera permission required',
              icon: Icons.face_outlined,
              complete: selfie,
              onTap: () => setState(() => selfie = true)),
          const SizedBox(height: 9),
          DemoEvidenceTile(
              key: const Key('demo-before'),
              title: before ? 'Before photo captured' : 'Capture demo before',
              subtitle: 'Seeded evidence',
              icon: Icons.photo_camera_outlined,
              complete: before,
              onTap: () => setState(() => before = true)),
          const SizedBox(height: 9),
          DemoEvidenceTile(
              key: const Key('demo-after'),
              title: after ? 'After photo captured' : 'Capture demo after',
              subtitle: 'Seeded evidence',
              icon: Icons.photo_camera_outlined,
              complete: after,
              onTap: () => setState(() => after = true)),
          const SizedBox(height: 18),
          FilledButton.icon(
            key: const Key('submit-proof'),
            onPressed: selfie && before && after
                ? () => setState(() {
                      widget.order.status = 'proof_submitted';
                      submitted = true;
                    })
                : null,
            style: FilledButton.styleFrom(backgroundColor: verified),
            icon: const Icon(Icons.shield_outlined),
            label: const Text('Submit verified proof'),
          )
        ]
      ]),
    );
  }
}
