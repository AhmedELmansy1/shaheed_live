// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

/// Generates the "Stands + Live Signal" (مدرّج) brand icons.
///
/// Palette:
/// - Background top: #0B1020
/// - Background bottom: #16213E
/// - Live dot: #FF4D3D
/// - Arcs: #FFFFFF with opacities 1.0, 0.90, 0.75, 0.50
void main() {
  print('[BrandingGenerator] Generating Modarraj brand icon suite...');

  // 1. Generate master 512x512 icon
  final master = _renderIcon(512, roundedCorner: false);
  final masterRounded = _renderIcon(512, roundedCorner: true, radius: 112);

  // Save to assets/branding/
  Directory('assets/branding').createSync(recursive: true);
  File('assets/branding/play_store_512.png').writeAsBytesSync(img.encodePng(master));
  File('assets/branding/modarraj_logo_512.png').writeAsBytesSync(img.encodePng(masterRounded));
  print('✓ Saved Play Store & Master 512x512 icons');

  // 2. Generate legacy Android mipmap icons (both launcher_icon.png and ic_launcher.png)
  final densities = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  for (final entry in densities.entries) {
    final folder = 'android/app/src/main/res/mipmap-${entry.key}';
    Directory(folder).createSync(recursive: true);

    final size = entry.value;
    final icon = _renderIcon(size, roundedCorner: true, radius: (size * 0.22).round());
    final pngBytes = img.encodePng(icon);

    File('$folder/launcher_icon.png').writeAsBytesSync(pngBytes);
    File('$folder/ic_launcher.png').writeAsBytesSync(pngBytes);
    print('✓ Generated $folder icons (${size}x$size)');
  }

  // 3. Generate Web icons
  Directory('assets/branding/web').createSync(recursive: true);
  final favicon = _renderIcon(32, roundedCorner: true, radius: 7);
  final web192 = _renderIcon(192, roundedCorner: true, radius: 42);
  final web512 = _renderIcon(512, roundedCorner: true, radius: 112);

  File('assets/branding/web/favicon.png').writeAsBytesSync(img.encodePng(favicon));
  File('assets/branding/web/icon-192.png').writeAsBytesSync(img.encodePng(web192));
  File('assets/branding/web/icon-512.png').writeAsBytesSync(img.encodePng(web512));
  print('✓ Saved Web icons (32, 192, 512)');

  // 4. Verification check
  for (final checkSize in [48, 96, 512]) {
    final testPath = checkSize == 512
        ? 'assets/branding/play_store_512.png'
        : checkSize == 96
            ? 'android/app/src/main/res/mipmap-xhdpi/launcher_icon.png'
            : 'android/app/src/main/res/mipmap-mdpi/launcher_icon.png';
    final f = File(testPath);
    if (!f.existsSync()) throw Exception('Missing generated icon at $testPath');
    final bytes = f.readAsBytesSync();
    final decoded = img.decodePng(bytes);
    if (decoded == null || decoded.width != checkSize || decoded.height != checkSize) {
      throw Exception('Icon at $testPath has invalid dimensions: ${decoded?.width}x${decoded?.height}');
    }
    print('✓ Verified icon at ${checkSize}px (${bytes.length} bytes)');
  }

  print('[BrandingGenerator] All brand icons generated and verified successfully!');
}

img.Image _renderIcon(int size, {bool roundedCorner = false, int radius = 0}) {
  final image = img.Image(width: size, height: size, numChannels: 4);

  // Background colors:
  // Top: #0B1020 (11, 16, 32)
  // Bottom: #16213E (22, 33, 62)
  for (var y = 0; y < size; y++) {
    final t = y / (size - 1);
    final r = (11 + (22 - 11) * t).round();
    final g = (16 + (33 - 16) * t).round();
    final b = (32 + (62 - 32) * t).round();

    for (var x = 0; x < size; x++) {
      if (roundedCorner) {
        // Round corner test
        final distToCorner = _distToRoundedCorner(x, y, size, radius);
        if (distToCorner > 0) {
          image.setPixelRgba(x, y, 0, 0, 0, 0);
          continue;
        }
      }
      image.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  // Scaling factor relative to 512 base
  final scale = size / 512.0;

  // Center of stands geometry
  final cx = size / 2.0;
  final cy = 330.0 * scale;

  // Tiers parameters (radius, strokeWidth, alpha, angleSpan)
  final tiers = [
    _Tier(r: 216.0 * scale, stroke: math.max(1.0, 14.0 * scale), alpha: 0.50, halfAngle: 68.0),
    _Tier(r: 168.0 * scale, stroke: math.max(1.5, 17.0 * scale), alpha: 0.75, halfAngle: 70.0),
    _Tier(r: 118.0 * scale, stroke: math.max(1.5, 16.0 * scale), alpha: 0.90, halfAngle: 66.0),
    _Tier(r: 68.0 * scale, stroke: math.max(1.5, 14.0 * scale), alpha: 1.00, halfAngle: 60.0),
  ];

  for (final tier in tiers) {
    _drawArc(
      image: image,
      cx: cx,
      cy: cy,
      radius: tier.r,
      strokeWidth: tier.stroke,
      alpha: tier.alpha,
      halfAngleDeg: tier.halfAngle,
    );
  }

  // Draw Live Red-Orange Dot at (cx, cy)
  // Color: #FF4D3D (255, 77, 61)
  final dotR = math.max(2.0, 23.0 * scale);
  _drawFilledCircle(
    image: image,
    cx: cx,
    cy: cy,
    radius: dotR,
    r: 255,
    g: 77,
    b: 61,
  );

  return image;
}

class _Tier {
  final double r;
  final double stroke;
  final double alpha;
  final double halfAngle;

  const _Tier({
    required this.r,
    required this.stroke,
    required this.alpha,
    required this.halfAngle,
  });
}

void _drawArc({
  required img.Image image,
  required double cx,
  required double cy,
  required double radius,
  required double strokeWidth,
  required double alpha,
  required double halfAngleDeg,
}) {
  final halfStroke = strokeWidth / 2.0;
  final rMin = radius - halfStroke;
  final rMax = radius + halfStroke;

  final minX = (cx - rMax - 1).floor().clamp(0, image.width - 1);
  final maxX = (cx + rMax + 1).ceil().clamp(0, image.width - 1);
  final minY = (cy - rMax - 1).floor().clamp(0, image.height - 1);
  final maxY = (cy + 2).ceil().clamp(0, image.height - 1);

  final halfAngleRad = (halfAngleDeg * math.pi) / 180.0;

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist >= rMin - 0.5 && dist <= rMax + 0.5 && dy <= 0) {
        // Angle from straight UP (-Y direction)
        final angleFromUp = math.atan2(dx.abs(), -dy);
        if (angleFromUp <= halfAngleRad) {
          // Radial anti-aliasing
          final radialDist = (dist - radius).abs();
          var coverage = 1.0;
          if (radialDist > halfStroke - 0.5) {
            coverage = math.max(0.0, 1.0 - (radialDist - (halfStroke - 0.5)));
          }

          final pixelAlpha = (255 * alpha * coverage).round().clamp(0, 255);
          if (pixelAlpha > 0) {
            _blendPixel(image, x, y, 255, 255, 255, pixelAlpha);
          }
        }
      }
    }
  }
}

void _drawFilledCircle({
  required img.Image image,
  required double cx,
  required double cy,
  required double radius,
  required int r,
  required int g,
  required int b,
}) {
  final minX = (cx - radius - 1).floor().clamp(0, image.width - 1);
  final maxX = (cx + radius + 1).ceil().clamp(0, image.width - 1);
  final minY = (cy - radius - 1).floor().clamp(0, image.height - 1);
  final maxY = (cy + radius + 1).ceil().clamp(0, image.height - 1);

  for (var y = minY; y <= maxY; y++) {
    for (var x = minX; x <= maxX; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final dist = math.sqrt(dx * dx + dy * dy);

      if (dist <= radius + 0.5) {
        var coverage = 1.0;
        if (dist > radius - 0.5) {
          coverage = math.max(0.0, 1.0 - (dist - (radius - 0.5)));
        }
        final a = (255 * coverage).round();
        if (a > 0) {
          _blendPixel(image, x, y, r, g, b, a);
        }
      }
    }
  }
}

void _blendPixel(img.Image image, int x, int y, int srcR, int srcG, int srcB, int srcA) {
  final bg = image.getPixel(x, y);
  final bgA = bg.a.toDouble() / 255.0;
  final sA = srcA.toDouble() / 255.0;

  final outA = sA + bgA * (1.0 - sA);
  if (outA <= 0) return;

  final outR = ((srcR * sA + bg.r * bgA * (1.0 - sA)) / outA).round().clamp(0, 255);
  final outG = ((srcG * sA + bg.g * bgA * (1.0 - sA)) / outA).round().clamp(0, 255);
  final outB = ((srcB * sA + bg.b * bgA * (1.0 - sA)) / outA).round().clamp(0, 255);

  image.setPixelRgba(x, y, outR, outG, outB, (outA * 255).round().clamp(0, 255));
}

double _distToRoundedCorner(int x, int y, int size, int radius) {
  var cx = 0;
  var cy = 0;
  if (x < radius && y < radius) {
    cx = radius;
    cy = radius;
  } else if (x >= size - radius && y < radius) {
    cx = size - radius - 1;
    cy = radius;
  } else if (x < radius && y >= size - radius) {
    cx = radius;
    cy = size - radius - 1;
  } else if (x >= size - radius && y >= size - radius) {
    cx = size - radius - 1;
    cy = size - radius - 1;
  } else {
    return -1.0;
  }

  final dx = x - cx;
  final dy = y - cy;
  final dist = math.sqrt(dx * dx + dy * dy);
  return dist - radius;
}
