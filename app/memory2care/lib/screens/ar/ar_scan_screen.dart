import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:memory2care/controllers/app_controller.dart';
import 'package:memory2care/models/medication.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ArScanScreen extends StatefulWidget {
  const ArScanScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<ArScanScreen> createState() => _ArScanScreenState();
}

class _ArScanScreenState extends State<ArScanScreen> {
  final MobileScannerController _scannerCtrl = MobileScannerController();
  Medication? _detected;
  bool _processing = false;

  bool get _scannerSupported => Platform.isAndroid || Platform.isIOS;

  @override
  void dispose() {
    _scannerCtrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_processing) return;
    final value = capture.barcodes.firstOrNull?.rawValue;
    if (value == null) return;

    final medication = widget.controller.medications.where((m) => m.id == value).firstOrNull;
    if (medication == null) return;

    setState(() {
      _processing = true;
      _detected = medication;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _processing = false);
    });
  }

  Future<void> _markTaken() async {
    final med = _detected;
    if (med == null) return;
    await widget.controller.toggleMedicationTaken(med.id, DateTime.now());
    if (mounted) {
      setState(() => _detected = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${med.name} marked as taken')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_scannerSupported) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Scan Medication'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.qr_code_scanner, size: 56),
                SizedBox(height: 16),
                Text(
                  'Medication scanning is available on mobile devices only.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Scan Medication'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              if (_scannerSupported) {
                _scannerCtrl.toggleTorch();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerCtrl,
            onDetect: _onDetect,
          ),
          _ScannerOverlay(),
          if (_detected != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _MedicationOverlayCard(
                medication: _detected!,
                controller: widget.controller,
                onMarkTaken: _markTaken,
                onDismiss: () => setState(() => _detected = null),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OverlayPainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const side = 220.0;
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;
    final rect = Rect.fromCenter(center: Offset(cx, cy), width: side, height: side);

    final paint = Paint()..color = Colors.black54;
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );

    final borderPaint = Paint()
      ..color = const Color(0xFF5D9CEC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MedicationOverlayCard extends StatelessWidget {
  const _MedicationOverlayCard({
    required this.medication,
    required this.controller,
    required this.onMarkTaken,
    required this.onDismiss,
  });

  final Medication medication;
  final AppController controller;
  final VoidCallback onMarkTaken;
  final VoidCallback onDismiss;

  String _lastIntakeText() {
    final today = DateTime.now();
    for (var i = 0; i < 30; i++) {
      final date = today.subtract(Duration(days: i));
      if (controller.isMedicationTaken(medication.id, date)) {
        return DateFormat('dd MMM yyyy').format(date);
      }
    }
    return 'No record';
  }

  String _nextIntakeText() {
    final today = DateTime.now();
    for (var i = 0; i < 30; i++) {
      final date = today.add(Duration(days: i));
      if (medication.isDueOn(date)) {
        if (i == 0 && controller.isMedicationTaken(medication.id, today)) continue;
        return i == 0 ? 'Today' : DateFormat('dd MMM yyyy').format(date);
      }
    }
    return 'No upcoming dose';
  }

  @override
  Widget build(BuildContext context) {
    final isTakenToday = controller.isMedicationTaken(medication.id, DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.medication, color: Color(0xFF5D9CEC), size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  medication.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onDismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            medication.dose,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _InfoRow(
            icon: Icons.history,
            label: 'Last intake',
            value: _lastIntakeText(),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.schedule,
            label: 'Next dose',
            value: _nextIntakeText(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isTakenToday ? null : onMarkTaken,
              icon: Icon(isTakenToday ? Icons.check_circle : Icons.check),
              label: Text(isTakenToday ? 'Already taken today' : 'Mark as taken'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black45),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.black54)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
