import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:pdf/widgets.dart' as pw;

import 'package:salesroot/core/fake/seed_graph.dart';

/// The bytes of a file that sits on this phone, or null when it is gone.
Future<Uint8List?> localFileBytes(String? path) async {
  if (path == null) return null;
  final file = File(path);
  return await file.exists() ? file.readAsBytes() : null;
}

/// Stand-in content for a fixture file, shaped by its extension.
Future<Uint8List> fakeFileBytes(String name, SeedGraph graph) async {
  final lower = name.toLowerCase();
  if (lower.endsWith('.pdf')) return _pdf(name, graph);
  if (RegExp(r'\.(jpe?g|png|heic|webp)$').hasMatch(lower)) {
    return fakePhotoBytes(name.hashCode);
  }
  return Uint8List.fromList(utf8.encode('$name\n\nSalesRoot sample file.'));
}

Future<Uint8List> _pdf(String name, SeedGraph graph) {
  final title = name.replaceAll('_', ' ').replaceAll('.pdf', '');
  final priced = name.toLowerCase().contains('price');
  final doc = pw.Document()
    ..addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Header(level: 0, text: title),
          if (priced)
            pw.TableHelper.fromTextArray(
              headers: ['Code', 'Product', 'Unit', 'Price (Tk)', 'Dealer (Tk)'],
              data: [
                for (final p in graph.products)
                  [p.code, p.name, p.unit, '${p.price}', '${p.dealerPrice}'],
              ],
            )
          else
            for (final p in graph.products.take(12))
              pw.Bullet(text: '${p.name} (${p.category})'),
        ],
      ),
    );
  return doc.save();
}

/// A small rooftop-solar picture as a 24-bit BMP: sky above a panel grid.
Uint8List fakePhotoBytes(int seed, {int width = 240, int height = 160}) {
  final rowSize = (width * 3 + 3) & ~3;
  final size = 54 + rowSize * height;
  final data = ByteData(size)
    ..setUint8(0, 0x42)
    ..setUint8(1, 0x4D)
    ..setUint32(2, size, Endian.little)
    ..setUint32(10, 54, Endian.little)
    ..setUint32(14, 40, Endian.little)
    ..setInt32(18, width, Endian.little)
    ..setInt32(22, height, Endian.little)
    ..setUint16(26, 1, Endian.little)
    ..setUint16(28, 24, Endian.little)
    ..setUint32(34, rowSize * height, Endian.little);
  final horizon = height * (0.35 + (seed.abs() % 20) / 100);
  for (var row = 0; row < height; row++) {
    final y = height - 1 - row;
    for (var x = 0; x < width; x++) {
      final (r, g, b) = y < horizon
          ? (150 + y * 80 ~/ height, 200 + y * 40 ~/ height, 245)
          : (x % 24 < 2 || (y - horizon.toInt()) % 18 < 2)
          ? (190, 196, 204)
          : (22, 42 + x * 30 ~/ width, 92);
      final offset = 54 + row * rowSize + x * 3;
      data
        ..setUint8(offset, b)
        ..setUint8(offset + 1, g)
        ..setUint8(offset + 2, r);
    }
  }
  return data.buffer.asUint8List();
}
