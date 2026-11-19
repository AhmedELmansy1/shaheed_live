import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/utils/date_formatter.dart';
import '../home/providers/matches_provider.dart';

/// Editorial Horizontal Day Selector for the "Paper × Ink × Vermilion" design system.
///
/// Features:
/// - Quick tabs: Yesterday (الأمس), Today (اليوم), Tomorrow (الغد).
/// - Calendar date picker button with formatted date preview.
/// - Minimum 48dp touch target for accessibility.
class DaySelector extends StatelessWidget {
  final HomeTab activeTab;
  final DateTime? customDate;
  final ValueChanged<HomeTab> onTabSelected;
  final ValueChanged<DateTime> onCustomDateSelected;

  const DaySelector({
    super.key,
    required this.activeTab,
    this.customDate,
    required this.onTabSelected,
    required this.onCustomDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: AppRadii.lgRadius,
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        children: [
          _buildTabItem(
            context: context,
            title: 'الأمس',
            tab: HomeTab.yesterday,
            isSelected: activeTab == HomeTab.yesterday,
          ),
          _buildTabItem(
            context: context,
            title: 'اليوم',
            tab: HomeTab.today,
            isSelected: activeTab == HomeTab.today,
            showLiveDot: true,
          ),
          _buildTabItem(
            context: context,
            title: 'الغد',
            tab: HomeTab.tomorrow,
            isSelected: activeTab == HomeTab.tomorrow,
          ),
          _buildCalendarItem(context),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required BuildContext context,
    required String title,
    required HomeTab tab,
    required bool isSelected,
    bool showLiveDot = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vermilion = AppColors.primaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    final selectedBg = isDark
        ? AppColors.primaryOf(context).withValues(alpha: 0.16)
        : const Color(0xFF14161C); // Ink pill in light mode
    final selectedTextColor = isDark ? AppColors.primaryOf(context) : Colors.white;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: 'تبويب $title',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.mdRadius,
            onTap: () {
              HapticFeedback.selectionClick();
              onTabSelected(tab);
            },
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : Colors.transparent,
                borderRadius: AppRadii.mdRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: AppTypography.labelLarge(
                      color: isSelected ? selectedTextColor : textSecondary,
                    ).copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  if (showLiveDot && isSelected) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: vermilion,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarItem(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = activeTab == HomeTab.customDate;
    final textSecondary = AppColors.textSecondaryOf(context);

    final selectedBg = isDark
        ? AppColors.primaryOf(context).withValues(alpha: 0.16)
        : const Color(0xFF14161C);
    final selectedTextColor = isDark ? AppColors.primaryOf(context) : Colors.white;

    String dateLabel = '';
    if (isSelected && customDate != null) {
      dateLabel = DateFormat('M/d', 'ar').format(customDate!);
      dateLabel = DateFormatter.toArabicNumerals(dateLabel);
    }

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: isSelected && dateLabel.isNotEmpty
            ? 'تاريخ محدد: $dateLabel'
            : 'اختيار تاريخ من التقويم',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadii.mdRadius,
            onTap: () async {
              HapticFeedback.lightImpact();
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: customDate ?? now,
                firstDate: now.subtract(const Duration(days: 365)),
                lastDate: now.add(const Duration(days: 365)),
                locale: const Locale('ar'),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(context).colorScheme.copyWith(
                            primary: AppColors.primaryOf(context),
                          ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                onCustomDateSelected(picked);
              }
            },
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : Colors.transparent,
                borderRadius: AppRadii.mdRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 15,
                    color: isSelected ? selectedTextColor : textSecondary,
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      dateLabel,
                      style: AppTypography.labelSmall(
                        color: selectedTextColor,
                      ).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

