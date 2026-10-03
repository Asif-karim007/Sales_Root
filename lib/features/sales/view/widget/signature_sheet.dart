import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:salesroot/core/theme/app_text.dart';
import 'package:salesroot/core/theme/sr_colors.dart';
import 'package:salesroot/l10n/l10n.dart';
import 'package:salesroot/widgets/widgets.dart';

/// Lets the customer sign on the screen; pops with the signature as a PNG.
Future<Uint8List?> showSignatureSheet(BuildContext context) =>
    showSrSheet<Uint8List>(
      context: context,
      isDismissible: false,
      builder: (_) => const _SignatureSheet(),
    );

class _SignatureSheet extends StatefulWidget {
  const _SignatureSheet();

  @override
  State<_SignatureSheet> createState() => _SignatureSheetState();
}

class _SignatureSheetState extends State<_SignatureSheet> {
  static const double _height = 220;

  final List<List<Offset>> _strokes = [];
  Size _size = Size.zero;

  Future<void> _done(Color ink) async {
    final recorder = ui.PictureRecorder();
    _SignaturePainter(
      strokes: _strokes,
      color: ink,
    ).paint(Canvas(recorder), _size);
    final image = await recorder.endRecording().toImage(
      _size.width.ceil(),
      _size.height.ceil(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (!mounted || data == null) return;
    Navigator.of(context).pop(data.buffer.asUint8List());
  }

  @override
  Widget build(BuildContext context) {
    final c = SrColors.of(context);
    final l10n = context.l10n;
    return SrSheet(
      title: l10n.salesSignature,
      subtitle: l10n.salesSignatureHint,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              _size = Size(constraints.maxWidth, _height);
              return GestureDetector(
                onPanStart: (d) =>
                    setState(() => _strokes.add([d.localPosition])),
                onPanUpdate: (d) =>
                    setState(() => _strokes.last.add(d.localPosition)),
                child: Container(
                  height: _height,
                  decoration: BoxDecoration(
                    color: c.canvas,
                    borderRadius: BorderRadius.circular(SrMetrics.radiusCard),
                    border: SrBorder.all(color: c.line),
                  ),
                  child: _strokes.isEmpty
                      ? Center(
                          child: Text(
                            l10n.salesSignHere,
                            style: AppText.meta(c.ink3),
                          ),
                        )
                      : CustomPaint(
                          painter: _SignaturePainter(
                            strokes: _strokes,
                            color: c.ink,
                          ),
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SrButton(
                  label: l10n.commonClear,
                  variant: SrButtonVariant.secondary,
                  onPressed: _strokes.isEmpty
                      ? null
                      : () => setState(_strokes.clear),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SrButton(
                  label: l10n.commonDone,
                  onPressed: _strokes.isEmpty ? null : () => _done(c.ink),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter({required this.strokes, required this.color});

  final List<List<Offset>> strokes;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.3, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_SignaturePainter old) => true;
}
