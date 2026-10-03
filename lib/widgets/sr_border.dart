import 'package:flutter/painting.dart';

/// A uniform [Border] that draws rounded corners as a single stroked outline
/// and skips transparent sides. `Border.all` fills the ring between two
/// rounded rects instead, which Impeller on OpenGL ES renders through a
/// stencil pass over the whole box on every frame.
class SrBorder extends Border {
  SrBorder.all({required Color color, double width = 1})
    : super.fromBorderSide(BorderSide(color: color, width: width));

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (top.color.a == 0) return;
    if (borderRadius == null || shape != BoxShape.rectangle) {
      super.paint(
        canvas,
        rect,
        textDirection: textDirection,
        shape: shape,
        borderRadius: borderRadius,
      );
      return;
    }
    canvas.drawRRect(
      borderRadius.toRRect(rect).deflate(top.width / 2),
      top.toPaint(),
    );
  }
}
