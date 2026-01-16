import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/statch_logo.dart';
import '../theme/app_theme.dart';

/// Helper class to generate the App Icon from code
class IconGenerator {
  /// Generates the app icon and saves it to the device's document directory.
  /// Call this function ONCE (e.g., from a button or main.dart temporarily)
  static Future<void> generateAndSaveIcon() async {
    const double size = 1024; // High resolution for Play Store
    
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    // 1. Draw Background (Dark theme for the icon looks premium)
    final Paint bgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(const Rect.fromLTWH(0, 0, size, size), bgPaint);

    // 2. Center the Logo
    // We make the logo occupy about 80% of the icon size
    const double logoSize = size * 0.8; 
    const double offset = (size - logoSize) / 2;
    
    canvas.save();
    canvas.translate(offset, offset);

    // 3. Paint the logo using your pure-code painter
    final painter = StatchLogoPainter(
      primaryColor: AppTheme.robinhoodGreen,
      secondaryColor: const Color(0xFF1F2937),
      isDark: true, // Force dark mode colors for the icon
    );
    
    painter.paint(canvas, const Size(logoSize, logoSize));
    canvas.restore();

    // 4. Convert to Image
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage(size.toInt(), size.toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      // 5. Save to device storage
      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/statch_icon.png';
      final File file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());
      
      debugPrint('----------------------------------------------------');
      debugPrint('ICON GENERATED SUCCESSFULLY!');
      debugPrint('Location: $filePath');
      debugPrint('Use "adb pull $filePath" to get it on your computer.');
      debugPrint('----------------------------------------------------');
    }
  }
}