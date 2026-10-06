import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/match_model.dart';
import '../providers/match_details_providers.dart';

class InfoTab extends ConsumerWidget {
  final MatchModel match;

  const InfoTab({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final infoAsync = ref.watch(matchInfoProvider(match.id));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Championship Card
        _buildSectionCard(
          title: 'البطولة والمعلومات العامة',
          icon: Icons.emoji_events,
          children: [
            if (match.leagueLogo != null && match.leagueLogo!.isNotEmpty)
              Row(
                children: [
                  CachedNetworkImage(
                    imageUrl: match.leagueLogo!,
                    width: 32,
                    height: 32,
                    errorWidget: (_, _, _) => const Icon(
                      Icons.emoji_events,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      match.leagueName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            else
              Text(
                match.leagueName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            infoAsync.when(
              data: (info) => info?.round != null
                  ? Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildInfoRow('المرحلة / الجولة', info!.round!),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Match Time Card
        _buildSectionCard(
          title: 'توقيت المباراة والتاريخ',
          icon: Icons.access_time,
          children: [
            _buildInfoRow(
              'التاريخ المحلّي',
              DateFormatter.toArabicNumerals(match.displayDate),
            ),
            const SizedBox(height: 8),
            _buildInfoRow('وقت الانطلاق', match.formattedLocalTime),
            const SizedBox(height: 8),
            _buildInfoRow('حالة المباراة', match.statusName),
          ],
        ),
        const SizedBox(height: 16),

        // Venue & Officials Card
        infoAsync.when(
          data: (info) {
            return _buildSectionCard(
              title: 'الملعب والتحكيم',
              icon: Icons.stadium,
              children: [
                _buildInfoRow(
                  'الملعب',
                  info?.stadium != null && info!.stadium!.isNotEmpty
                      ? info.stadium!
                      : 'غير محدد',
                ),
                const SizedBox(height: 8),
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
            icon: Icons.stadium,
            children: const [
              Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          error: (err, _) => _buildSectionCard(
            title: 'الملعب والتحكيم',
            icon: Icons.stadium,
            children: [
              Text(
                'خطأ: $err',
                style: const TextStyle(color: AppColors.livePulse),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: AppColors.cardBorder, height: 24),
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
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
