import 'package:flutter/material.dart';
import 'package:moment/core/theme/app_colors.dart';
import 'package:moment/features/shared_pet/engine/pet_room_layout.dart';

class PetRoom extends StatelessWidget {
  const PetRoom({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return CustomPaint(
          size: size,
          painter: _PetRoomPainter(size: size),
        );
      },
    );
  }
}

class _PetRoomPainter extends CustomPainter {
  _PetRoomPainter({required this.size});

  final Size size;

  @override
  void paint(Canvas canvas, Size size) {
    final floor = Rect.fromLTWH(0, size.height * 0.35, size.width, size.height * 0.65);
    final floorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF2A2438),
          const Color(0xFF1A1524),
        ],
      ).createShader(floor);
    canvas.drawRect(floor, floorPaint);

    final wallPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF3D2F4A), Color(0xFF251E32)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.45));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.45), wallPaint);

    _drawProp(canvas, PetRoomAnchor.foodBowl, Icons.restaurant, AppColors.sendCoral);
    _drawProp(canvas, PetRoomAnchor.waterBowl, Icons.water_drop, const Color(0xFF6EC6FF));
    _drawProp(canvas, PetRoomAnchor.bed, Icons.bed, AppColors.nextPurple);
    _drawProp(canvas, PetRoomAnchor.toy, Icons.toys, AppColors.photoPink);

    final windowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.78, size.height * 0.18),
        width: size.width * 0.22,
        height: size.height * 0.14,
      ),
      const Radius.circular(8),
    );
    canvas.drawRRect(
      windowRect,
      Paint()..color = const Color(0x66FFE8A3),
    );
  }

  void _drawProp(Canvas canvas, PetRoomAnchor anchor, IconData icon, Color color) {
    final offset = anchor.toScreenOffset(size);
    final circle = Paint()..color = color.withValues(alpha: 0.25);
    canvas.drawCircle(offset, 22, circle);
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 22,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      offset - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _PetRoomPainter oldDelegate) => false;
}
