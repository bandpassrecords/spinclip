/// Position (as a fraction of frame width/height, 0.0-1.0, anchored at the
/// element's center) and rotation (degrees, clockwise) for a draggable
/// overlay element (cover, logo, QR code). Fractions keep the same visual
/// layout across every aspect ratio/platform preset.
class ElementTransform {
  final double dx;
  final double dy;
  final double rotationDegrees;

  const ElementTransform({
    this.dx = 0.5,
    this.dy = 0.5,
    this.rotationDegrees = 0,
  });

  static const center = ElementTransform(dx: 0.5, dy: 0.5);
  static const bottomRight = ElementTransform(dx: 0.90, dy: 0.90);
  static const bottomLeft = ElementTransform(dx: 0.10, dy: 0.90);
  static const bottomCenter = ElementTransform(dx: 0.5, dy: 0.85);

  ElementTransform copyWith({double? dx, double? dy, double? rotationDegrees}) {
    return ElementTransform(
      dx: dx ?? this.dx,
      dy: dy ?? this.dy,
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ElementTransform &&
      other.dx == dx &&
      other.dy == dy &&
      other.rotationDegrees == rotationDegrees;

  @override
  int get hashCode => Object.hash(dx, dy, rotationDegrees);
}
