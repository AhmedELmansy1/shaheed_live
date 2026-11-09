import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Reusable Team Logo widget in "Paper × Ink × Vermilion" design system.
///
/// Features:
/// - Circular soft paper/ink frame with crisp 1px border.
/// - Downsampled GPU memory cache (memCacheWidth & memCacheHeight).
/// - Elegant fallback initials in Cairo bold.
/// - Hero animation support.
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
        style: AppTypography.labelLarge(
          color: AppColors.textSecondaryOf(context),
        ).copyWith(
          fontSize: (size * 0.35).clamp(9.0, 16.0),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cacheDim = (size * 2).round().clamp(48, 160);
    Widget imageContent;

    if (logoUrl != null && logoUrl!.isNotEmpty) {
      imageContent = CachedNetworkImage(
        imageUrl: logoUrl!,
        width: size * 0.72,
        height: size * 0.72,
        fit: BoxFit.contain,
        memCacheWidth: cacheDim,
        memCacheHeight: cacheDim,
        maxWidthDiskCache: 200,
        maxHeightDiskCache: 200,
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
        color: AppColors.surfaceElevatedOf(context),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.borderOf(context),
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
