import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radii.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_model.dart';
import '../../widgets/app_card.dart';
import '../providers/match_details_providers.dart';

class InfoTab extends ConsumerWidget {
  final MatchModel match;

  const InfoTab({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(matchInfoProvider(match.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
      children: [
        // Championship Card
        _buildSectionCard(
          title: 'البطولة والمعلومات العامة',
          icon: Icons.emoji_events_rounded,
          children: [
            if (match.leagueLogo != null && match.leagueLogo!.isNotEmpty)
              Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: match.leagueLogo!,
                    width: 32,
                    height: 32,
                    errorWidget: (_, _, _) => const Icon(
                      Icons.emoji_events_rounded,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      match.leagueName,
                      style: AppTypography.titleSmall(color: AppColors.darkTextPrimary),
                    ),
                  ),
                ],
              )
            else
              Text(
                match.leagueName,
                style: AppTypography.titleSmall(color: AppColors.darkTextPrimary),
              ),
            infoAsync.when(
              data: (info) => info?.round != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: _buildInfoRow('المرحلة / الجولة', info!.round!),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Match Time Card
        _buildSectionCard(
          title: 'توقيت المباراة والتاريخ',
          icon: Icons.access_time_rounded,
          children: [
            _buildInfoRow('التاريخ المحلّي', DateFormatter.toArabicNumerals(match.displayDate)),
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow('وقت الانطلاق', match.formattedLocalTime),
            const SizedBox(height: AppSpacing.xs),
            _buildInfoRow('حالة المباراة', match.statusName),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Venue & Officials Card
        infoAsync.when(
          data: (info) {
            return _buildSectionCard(
              title: 'الملعب والتحكيم',
              icon: Icons.stadium_rounded,
              children: [
                _buildInfoRow(
                  'الملعب',
                  info?.stadium != null && info!.stadium!.isNotEmpty
                      ? info.stadium!
                      : 'غير محدد',
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildInfoRow(
                  'حكم المباراة',
                  info?.refereeName != null && info!.refereeName!.isNotEmpty
                      ? info.refereeName!
                      : 'غير محدد',
                ),
              ],
            );
          },
          loading: () => _buildSectionCard(
            title: 'الملعب والتحكيم',
            icon: Icons.stadium_rounded,
            children: const [
              Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ],
          ),
          error: (err, _) => _buildSectionCard(
            title: 'الملعب والتحكيم',
            icon: Icons.stadium_rounded,
            children: [
              Text(
                'خطأ: $err',
                style: AppTypography.caption(color: AppColors.live),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadii.xs),
                ),
                child: Icon(icon, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title,
                style: AppTypography.titleSmall(color: AppColors.darkTextPrimary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(color: AppColors.darkDivider, height: 1),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall(color: AppColors.darkTextSecondary),
        ),
        Text(
          value,
          style: AppTypography.bodySmall(color: AppColors.darkTextPrimary),
        ),
      ],
    );
  }
}
