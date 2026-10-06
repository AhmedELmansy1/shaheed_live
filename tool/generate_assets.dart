import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  const size = 512;
  final image = img.Image(width: size, height: size);
  
  // Fill background #121212
  img.fill(image, color: img.ColorRgb8(0x12, 0x12, 0x12));

  // Draw outer live accent ring (#D4AF37 Royal Gold)
  img.drawCircle(image, x: 256, y: 256, radius: 200, color: img.ColorRgb8(0xD4, 0xAF, 0x37));
  img.drawCircle(image, x: 256, y: 256, radius: 185, color: img.ColorRgb8(0x0A, 0x0E, 0x1A));

  // Draw filled central ball core (#D4AF37 Royal Gold)
  img.fillCircle(image, x: 256, y: 256, radius: 130, color: img.ColorRgb8(0xD4, 0xAF, 0x37));

  // Draw inner dark pentagon/circle motif (#12182A Deep Navy)
  img.fillCircle(image, x: 256, y: 256, radius: 60, color: img.ColorRgb8(0x12, 0x18, 0x2A));

  final png = img.encodePng(image);
  Directory('assets/images').createSync(recursive: true);
  File('assets/images/app_icon.png').writeAsBytesSync(png);
  stdout.writeln('App icon generated successfully at assets/images/app_icon.png');
}
