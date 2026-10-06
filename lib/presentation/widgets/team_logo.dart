import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Reusable Team Logo widget with circular soft ring, Hero animation tag support, and graceful initials fallback.
class TeamLogo extends StatelessWidget {
  final String? logoUrl;
  final String teamName;
  final double size;
  final String? heroTag;

  const TeamLogo({
    super.key,
    required this.logoUrl,
    required this.teamName,
    this.size = 40.0,
    this.heroTag,
  });

  String get _fallbackInitials {
    final trimmed = teamName.trim();
    if (trimmed.isEmpty) return '⚽';
    final parts = trimmed.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return trimmed.length > 2 ? trimmed.substring(0, 2) : trimmed;
  }

  Widget _buildFallback(BuildContext context) {
    return Center(
      child: Text(
        _fallbackInitials,
        style: GoogleFonts.cairo(
          color: AppColors.textSecondaryOf(context),
          fontSize: (size * 0.35).clamp(9.0, 16.0),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    Widget imageContent;

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size * 0.72,
        height: size * 0.72,
        fit: BoxFit.contain,
        placeholder: (context, url) => _buildFallback(context),
        errorWidget: (context, url, error) => _buildFallback(context),
      );
    } else {
      imageContent = _buildFallback(context);
    }

    final container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLight ? AppColors.lightSurfaceHigh : AppColors.darkSurfaceHigh,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLight ? AppColors.lightBorder : AppColors.darkBorder,
          width: 1.0,
        ),
      ),
      child: Center(child: imageContent),
    );

    if (heroTag != null && heroTag!.isNotEmpty) {
      return Hero(tag: heroTag!, child: container);
    }

    return container;
  }
}
