import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_constants.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/data_saver_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_motion.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/timezone_helper.dart';
import '../home/providers/matches_provider.dart';
import '../onboarding/providers/onboarding_provider.dart';
import '../diagnostics/diagnostics_screen.dart';
import '../match_details/widgets/stream_report_sheet.dart';
import '../widgets/app_card.dart';
import '../widgets/battery_guidance_dialog.dart';

/// Provider for notification preference toggles.
final notificationSettingsProvider =
    NotifierProvider<NotificationSettingsNotifier, ({bool matchStart, bool goalAlerts, String goalSound})>(
  () => NotificationSettingsNotifier(),
);

class NotificationSettingsNotifier
    extends Notifier<({bool matchStart, bool goalAlerts, String goalSound})> {
  static const String _matchStartKey = 'pref_notify_match_start';
  static const String _goalAlertsKey = 'pref_notify_goal_alerts';
  static const String _goalSoundKey = 'pref_notify_goal_sound';

  @override
  ({bool matchStart, bool goalAlerts, String goalSound}) build() {
    _load();
    return (matchStart: true, goalAlerts: true, goalSound: 'whistle');
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = (
      matchStart: prefs.getBool(_matchStartKey) ?? true,
      goalAlerts: prefs.getBool(_goalAlertsKey) ?? true,
      goalSound: prefs.getString(_goalSoundKey) ?? 'whistle',
    );
  }

  Future<void> setMatchStart(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_matchStartKey, value);
    state = (matchStart: value, goalAlerts: state.goalAlerts, goalSound: state.goalSound);
  }

  Future<void> setGoalAlerts(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_goalAlertsKey, value);
    state = (matchStart: state.matchStart, goalAlerts: value, goalSound: state.goalSound);
  }

  Future<void> setGoalSound(String sound) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_goalSoundKey, sound);
    state = (matchStart: state.matchStart, goalAlerts: state.goalAlerts, goalSound: sound);
  }
}

/// Clean, focused Settings screen for Shoot Live.
///
/// Features strictly wired, production-ready controls:
/// - Appearance (Theme mode: Dark, Light, System)
/// - Notifications (Match start reminders & Goal alerts toggles, Battery guidance)
/// - Favorites (Followed leagues & Favorite clubs management)
/// - Cache Management (View estimated cache footprint & Clear cache)
/// - About & Legal (App version, Developer profile, Privacy Policy, Terms of Service)
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _cacheFootprint = 'جاري الحساب...';
  bool _isClearingCache = false;
  int _diagnosticTapCount = 0;
  int _timezoneOffset = DateFormatter.globalKickoffOffsetHours;

  @override
  void initState() {
    super.initState();
    _computeCacheFootprint();
    _loadTimezoneOffset();
  }

  Future<void> _loadTimezoneOffset() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('pref_user_timezone_offset') ?? DateFormatter.globalKickoffOffsetHours;
    if (mounted) {
      setState(() {
        _timezoneOffset = saved;
        DateFormatter.globalKickoffOffsetHours = saved;
      });
    }
  }

  Future<void> _setTimezoneOffset(int offset) async {
    HapticFeedback.selectionClick();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_user_timezone_offset', offset);
    setState(() {
      _timezoneOffset = offset;
      DateFormatter.globalKickoffOffsetHours = offset;
    });
    ref.read(matchesProvider.notifier).refresh();
  }

  Future<void> _requestLocationAndTimezone() async {
    HapticFeedback.mediumImpact();
    try {
      final status = await Permission.locationWhenInUse.request();
      await TimezoneHelper.init();
      ref.read(matchesProvider.notifier).refresh();
      if (mounted) {
        final desc = TimezoneHelper.deviceTimezoneDescription;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status.isGranted
                  ? 'تم التحقق من موقعك وضبط توقيت المباريات تلقائياً ($desc) 📍'
                  : 'يتم استخدام توقيت جهازك الحالي تلقائياً ($desc)',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('توقيتك الحالي: ${TimezoneHelper.deviceTimezoneDescription}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _computeCacheFootprint() async {
    final prefs = await SharedPreferences.getInstance();
    final keysCount = prefs.getKeys().length;
    final approxMb = (keysCount * 0.15 + 1.2).toStringAsFixed(1);
    if (mounted) {
      setState(() {
        _cacheFootprint = '${DateFormatter.toArabicNumerals(approxMb)} ميجابايت';
      });
    }
  }

  Future<void> _clearCache() async {
    setState(() => _isClearingCache = true);
    HapticFeedback.mediumImpact();

    try {
      final cacheService = CacheService();
      await cacheService.clearAll();
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();

      if (mounted) {
        setState(() {
          _cacheFootprint = '${DateFormatter.toArabicNumerals('0.0')} ميجابايت';
          _isClearingCache = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم مسح الذاكرة المؤقتة بنجاح'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClearingCache = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل مسح الذاكرة المؤقتة: $e'),
            backgroundColor: AppColors.live,
          ),
        );
      }
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getGoalSoundLabel(String sound) {
    switch (sound) {
      case 'whistle':
        return 'صافرة الحكم الكروية (افتراضي)';
      case 'cheer':
        return 'هتاف الجمهور والمعلق الكروي';
      case 'system':
        return 'نغمة النظام الافتراضية';
      case 'silent':
        return 'صامت (اهتزاز فقط)';
      default:
        return 'صافرة الحكم الكروية';
    }
  }

  void _showGoalSoundSelector(BuildContext context, String currentSound) {
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final border = AppColors.borderOf(context);

    final sounds = [
      (key: 'whistle', title: 'صافرة الحكم الكروية', desc: 'نغمة كروية أصيلة بصوت صافرة الحكم الرسمية'),
      (key: 'cheer', title: 'هتاف الجمهور والمعلق', desc: 'حماس المدرجات وهتاف الهدف الكروي'),
      (key: 'system', title: 'نغمة النظام الافتراضية', desc: 'نغمة الإشعارات القياسية لنظام الهاتف'),
      (key: 'silent', title: 'صامت (اهتزاز فقط)', desc: 'تنبيه بصري مع اهتزاز دون صوت'),
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'اختر نغمة تنبيه الأهداف',
                  style: AppTypography.titleMedium(color: textPrimary).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'سيتم تشغيل هذه النغمة فور تسجيل هدف لأحد أنديتك المفضلة',
                  style: AppTypography.bodySmall(color: textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                ...sounds.map((s) {
                  final isSelected = currentSound == s.key;
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref.read(notificationSettingsProvider.notifier).setGoalSound(s.key);
                      Navigator.of(ctx).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? AppColors.primary : textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: AppTypography.bodyMedium(
                                    color: isSelected ? AppColors.primary : textPrimary,
                                  ).copyWith(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  s.desc,
                                  style: AppTypography.caption(color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final onboardingState = ref.watch(onboardingProvider);
    final notifSettings = ref.watch(notificationSettingsProvider);

    final favoriteCount = onboardingState.selectedTeamIds.length;
    final leagueCount = onboardingState.selectedLeagueIds.length;
    final isLight = Theme.of(context).brightness == Brightness.light;

    final textPrimary = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final textSecondary = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;
    final textMuted = isLight
        ? AppColors.lightTextMuted
        : AppColors.darkTextMuted;
    final border = isLight
        ? AppColors.lightBorder
        : AppColors.darkBorder;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'إعدادات التطبيق',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          120,
        ),
        children: [
          // 1. Theme / Appearance Section
          _buildSectionHeader('المظهر العام', textSecondary),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Row(
              children: [
                _buildThemeOption(
                  label: 'داكن',
                  icon: Icons.dark_mode_rounded,
                  mode: ThemeMode.dark,
                  isSelected: themeMode == ThemeMode.dark,
                  isLight: isLight,
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildThemeOption(
                  label: 'فاتح',
                  icon: Icons.light_mode_rounded,
                  mode: ThemeMode.light,
                  isSelected: themeMode == ThemeMode.light,
                  isLight: isLight,
                ),
                const SizedBox(width: AppSpacing.xs),
                _buildThemeOption(
                  label: 'تلقائي',
                  icon: Icons.settings_brightness_rounded,
                  mode: ThemeMode.system,
                  isSelected: themeMode == ThemeMode.system,
                  isLight: isLight,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 2. Notifications Section
          _buildSectionHeader('الإشعارات والتنبيهات', textSecondary),
          AppCard(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  title: Text(
                    'تنبيه قبل بدء المباراة',
                    style: AppTypography.titleSmall(color: textPrimary),
                  ),
                  subtitle: Text(
                    'إشعار تذكيري قبل انطلاق مباريات أنديتك المفضلة بـ 15 دقيقة',
                    style: AppTypography.caption(color: textSecondary),
                  ),
                  value: notifSettings.matchStart,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .setMatchStart(val);
                  },
                ),
                Divider(color: border, height: 1),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primary,
                  title: Text(
                    'تنبيهات الأهداف والأحداث المباشرة',
                    style: AppTypography.titleSmall(color: textPrimary),
                  ),
                  subtitle: Text(
                    'إشعار فوري عند تسجيل الأهداف والبطاقات الحمراء في المباريات الجارية',
                    style: AppTypography.caption(color: textSecondary),
                  ),
                  value: notifSettings.goalAlerts,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .setGoalAlerts(val);
                  },
                ),
                Divider(color: border, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.sports_soccer_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  title: Text(
                    'نغمة إشعار الأهداف المخصصة',
                    style: AppTypography.titleSmall(color: textPrimary),
                  ),
                  subtitle: Text(
                    _getGoalSoundLabel(notifSettings.goalSound),
                    style: AppTypography.caption(color: AppColors.primary).copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textMuted,
                    size: 15,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showGoalSoundSelector(context, notifSettings.goalSound);
                  },
                ),
                Divider(color: border, height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.battery_charging_full_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  title: Text(
                    'إرشادات تحسين وصول الإشعارات والبطارية',
                    style: AppTypography.titleSmall(color: textPrimary),
                  ),
                  subtitle: Text(
                    'تعطيل قيود البطارية لهواتف أندرويد لضمان استلام التنبيهات بدقة',
                    style: AppTypography.caption(color: textSecondary),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textMuted,
                    size: 15,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showBatteryOptimizationDialog(context, isManual: true);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Data Saver & Network Section
          _buildSectionHeader('الشبكة واستهلاك البيانات', textSecondary),
          AppCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: SwitchListTile.adaptive(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
              activeTrackColor: AppColors.primary,
              secondary: const Icon(
                Icons.data_saver_on_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              title: Text(
                'وضع توفير البيانات المتطور (Data Saver)',
                style: AppTypography.titleSmall(color: textPrimary),
              ),
              subtitle: Text(
                'تفضيل جودات البث الخفيفة تلقائياً وترشيد استهلاك باقة الإنترنت',
                style: AppTypography.caption(color: textSecondary),
              ),
              value: ref.watch(dataSaverModeProvider),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                ref.read(dataSaverModeProvider.notifier).setEnabled(val);
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Timezone & Location Section
          _buildSectionHeader('التوقيت والمنطقة الجغرافية', textSecondary),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(
                        Icons.access_time_filled_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'توقيت انطلاق المباريات',
                            style: AppTypography.titleSmall(color: textPrimary),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            TimezoneHelper.deviceTimezoneDescription,
                            style: AppTypography.caption(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _requestLocationAndTimezone,
                      icon: const Icon(Icons.my_location_rounded, size: 16),
                      label: const Text('تحديث 📍'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.full),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'يتم تحويل مواعيد المباريات تلقائياً لتوافق توقيت مدينتك. اضغط تحديث لطلب إذن الموقع الجغرافي وتعيين التوقيت الدقيق.',
                  style: AppTypography.caption(color: textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                Divider(color: border, height: 1),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      'تعديل الفارق الزمني يدوياً:',
                      style: AppTypography.caption(color: textPrimary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final off in [-2, -1, 0, 1, 2])
                      ChoiceChip(
                        label: Text(
                          off == 0
                              ? 'تلقائي (0)'
                              : (off > 0 ? '+$off س' : '$off س'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _timezoneOffset == off ? FontWeight.bold : FontWeight.normal,
                            color: _timezoneOffset == off
                                ? (isLight ? Colors.white : AppColors.darkBackground)
                                : textPrimary,
                          ),
                        ),
                        selected: _timezoneOffset == off,
                        selectedColor: AppColors.primary,
                        backgroundColor: isLight ? Colors.grey.shade100 : Colors.white.withValues(alpha: 0.05),
                        side: BorderSide(
                          color: _timezoneOffset == off
                              ? AppColors.primary
                              : border,
                        ),
                        onSelected: (_) => _setTimezoneOffset(off),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Favorites Management Section
          _buildSectionHeader('المفضلة والمتابعة', textSecondary),
          AppCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  title: Text(
                    'إدارة البطولات المتابعة',
                    style: AppTypography.titleSmall(color: textPrimary),
                  ),
                  subtitle: Text(
                    '${DateFormatter.toArabicNumerals('$leagueCount')} بطولة مختارة',
                    style: AppTypography.caption(color: textSecondary),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textMuted,
                    size: 15,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/settings/leagues');
                  },
                ),
                Divider(color: border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.star_rounded,
                    color: AppColors.gold,
                    size: 22,
                  ),
                  title: Text(
                    'إدارة الأندية المفضلة',
                    style: AppTypography.titleSmall(color: textPrimary),
                  ),
                  subtitle: Text(
                    '${DateFormatter.toArabicNumerals('$favoriteCount')} نادٍ مفضل',
                    style: AppTypography.caption(color: textSecondary),
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textMuted,
                    size: 15,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/favorites');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Cache Management Section
          _buildSectionHeader('الذاكرة المؤقتة', textSecondary),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                  ),
                  child: const Icon(
                    Icons.storage_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مساحة التخزين المؤقت',
                        style: AppTypography.titleSmall(color: textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _cacheFootprint,
                        style: AppTypography.caption(color: textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _isClearingCache ? null : _clearCache,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    foregroundColor: AppColors.primary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                  child: _isClearingCache
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'مسح',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 5. Stream Reports & Support Section
          _buildSectionHeader('مركز البلاغات والدعم الفني', textSecondary),
          AppCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: ListTile(
              leading: const Icon(
                Icons.support_agent_rounded,
                color: Colors.amber,
                size: 22,
              ),
              title: Text(
                'مركز بلاغات وملاحظات البث المباشر',
                style: AppTypography.titleSmall(color: textPrimary),
              ),
              subtitle: Text(
                'إرسال ملاحظة أو بلاغ عن تقطيع أو توقف في خوادم البث المباشر',
                style: AppTypography.caption(color: textSecondary),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                color: textMuted,
                size: 15,
              ),
              onTap: () {
                HapticFeedback.lightImpact();
                StreamReportBottomSheet.show(
                  context,
                  matchId: 0,
                  matchTitle: 'ملاحظة عامة على خوادم البث',
                  serverId: 'general_feedback',
                  serverName: 'مركز الدعم الفني',
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 6. About & Legal Section
          _buildSectionHeader('حول التطبيق', textSecondary),
          AppCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  title: Text(
                    'سياسة الخصوصية',
                    style: AppTypography.titleSmall(color: textPrimary),
                  ),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    color: textMuted,
                    size: 16,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _openUrl('https://shootlive.app/privacy');
                  },
                ),
                Divider(color: border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.gavel_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  title: Text(
                    'شروط الاستخدام والخدمة',
                    style: AppTypography.titleSmall(color: textPrimary),
                  ),
                  trailing: Icon(
                    Icons.open_in_new_rounded,
                    color: textMuted,
                    size: 16,
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _openUrl('https://shootlive.app/terms');
                  },
                ),
                if (kEnableDiagnostics) ...[
                  Divider(height: 1, thickness: 0.5, color: border),
                  ListTile(
                    leading: const Icon(Icons.bug_report_rounded, color: AppColors.primary),
                    title: Text(
                      'تشخيص النظام (Diagnostics)',
                      style: AppTypography.titleSmall(color: textPrimary),
                    ),
                    subtitle: Text(
                      'أدوات فحص الإشعارات والصلاحيات',
                      style: AppTypography.caption(color: textMuted),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: textMuted,
                      size: 14,
                    ),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.push('/diagnostics');
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // App Version Footer (Tap 5 times when diagnostics enabled)
          GestureDetector(
            onTap: () {
              if (kEnableDiagnostics) {
                _diagnosticTapCount++;
                if (_diagnosticTapCount >= 5) {
                  _diagnosticTapCount = 0;
                  context.push('/diagnostics');
                }
              }
            },
            child: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '1.0.0';
                final build = snapshot.data?.buildNumber ?? '1';
                return Center(
                  child: Text(
                    '${AppConstants.appName} • الإصدار ${DateFormatter.toArabicNumerals(version)} (${DateFormatter.toArabicNumerals(build)})',
                    style: AppTypography.caption(color: textMuted),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, right: AppSpacing.xs),
      child: Text(
        title,
        style: AppTypography.labelMedium(color: color).copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool isSelected,
    required bool isLight,
  }) {
    final unselectedBg = isLight
        ? AppColors.lightSurfaceHigh
        : const Color(0xFF141F36);
    final unselectedBorder = isLight
        ? AppColors.lightBorder
        : const Color(0xFF1E2D4A);
    final unselectedColor = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          ref.read(themeModeProvider.notifier).setThemeMode(mode);
        },
        child: AnimatedContainer(
          duration: AppMotion.fast,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? null : unselectedBg,
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.electricBlue.withValues(alpha: 0.22),
                      AppColors.electricCyan.withValues(alpha: 0.10),
                    ],
                  )
                : null,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.electricCyan : unselectedBorder,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppColors.electricCyan.withValues(alpha: 0.14),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.electricCyan.withValues(alpha: 0.18)
                      : (isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 18,
                  color: isSelected ? AppColors.electricCyan : unselectedColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTypography.caption(
                  color: isSelected ? AppColors.electricCyan : unselectedColor,
                ).copyWith(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
