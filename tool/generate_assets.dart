import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 512;
  final image = img.Image(width: size, height: size);
  
  // Fill background #121212
  img.fill(image, color: img.ColorRgb8(0x12, 0x12, 0x12));

  // Draw outer live accent ring (#00E676)
  img.drawCircle(image, x: 256, y: 256, radius: 200, color: img.ColorRgb8(0x00, 0xE6, 0x76));
  img.drawCircle(image, x: 256, y: 256, radius: 185, color: img.ColorRgb8(0x12, 0x12, 0x12));

  // Draw filled central ball core (#00E676)
  img.fillCircle(image, x: 256, y: 256, radius: 130, color: img.ColorRgb8(0x00, 0xE6, 0x76));

  // Draw inner dark pentagon/circle motif (#1E1E24)
  img.fillCircle(image, x: 256, y: 256, radius: 60, color: img.ColorRgb8(0x1E, 0x1E, 0x24));

  final png = img.encodePng(image);
  Directory('assets/images').createSync(recursive: true);
  File('assets/images/app_icon.png').writeAsBytesSync(png);
  stdout.writeln('App icon generated successfully at assets/images/app_icon.png');
}
