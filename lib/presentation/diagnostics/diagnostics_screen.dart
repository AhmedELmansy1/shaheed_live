import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/fcm_service.dart';
import '../../core/services/firebase_ready_provider.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/remote_config_service.dart';
import '../../core/services/sync_queue_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radii.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../widgets/app_card.dart';

/// Hidden diagnostics feature flag, enabled only when `--dart-define=ENABLE_DIAGNOSTICS=true` is passed.
const bool kEnableDiagnostics = bool.fromEnvironment('ENABLE_DIAGNOSTICS', defaultValue: false);

class DiagnosticsScreen extends ConsumerStatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  bool _isLoading = true;
  String? _appVersion;
  String? _packageName;
  String? _firebaseProjectId;
  PermissionStatus? _notificationPermissionStatus;
  bool? _exactAlarmStatus;
  List<AndroidNotificationChannel>? _channels;
  String? _fcmToken;
  String? _authUid;
  bool? _isAnonymous;
  String? _firebaseInitStatusText;
  bool _firebaseInitReady = false;
  String? _pendingSyncStatusText;
  bool _isSyncClean = true;
  List<String> _subscribedTopics = [];
  bool _isTestTopicEnabled = false;
  int _pendingRemindersCount = 0;
  List<PendingNotificationRequest> _pendingReminders = [];
  Map<String, dynamic>? _remoteConfigData;

  // Live collection read tests
  Map<String, String> _collectionTestResults = {};
  bool _isTestingCollections = false;

  @override
  void initState() {
    super.initState();
    _loadAllDiagnostics();
  }

  Future<void> _loadAllDiagnostics() async {
    setState(() => _isLoading = true);

    try {
      // 1. Package Info
      final pkg = await PackageInfo.fromPlatform();
      _appVersion = '${pkg.version} (${pkg.buildNumber})';
      _packageName = pkg.packageName;

      // 2. Firebase Initialization Status & Duration
      try {
        final readyState = ref.read(firebaseReadyProvider);
        if (readyState.isReady) {
          _firebaseInitStatusText = 'جاهز ومفعل (${readyState.initDurationMs}ms)';
          _firebaseInitReady = true;
        } else if (readyState.status == FirebaseInitStatus.failed) {
          _firebaseInitStatusText = 'فشل (${readyState.initDurationMs}ms): ${readyState.error}';
          _firebaseInitReady = false;
        } else {
          _firebaseInitStatusText = 'قيد التهيئة أو غير مفعل';
          _firebaseInitReady = false;
        }
      } catch (e) {
        _firebaseInitStatusText = 'غير متاح ($e)';
        _firebaseInitReady = false;
      }

      // 3. Deferred Cloud Sync State (Pending Sync Queue)
      try {
        final syncQueue = ref.read(syncQueueServiceProvider);
        _pendingSyncStatusText = await syncQueue.getSyncStatusDescription();
        final hasPending = await syncQueue.hasPendingSync();
        _isSyncClean = !hasPending;
      } catch (e) {
        _pendingSyncStatusText = 'خطأ في الفحص: $e';
        _isSyncClean = false;
      }

      // 4. Firebase Project ID & Auth Status
      try {
        _firebaseProjectId = Firebase.app().options.projectId;
        final authUser = FirebaseAuth.instance.currentUser;
        _authUid = authUser?.uid ?? 'غير مسجل (سيتم التسجيل المجهول تلقائياً)';
        _isAnonymous = authUser?.isAnonymous ?? false;
      } catch (e) {
        _firebaseProjectId = 'Error: $e';
        _authUid = 'Auth unavailable: $e';
      }

      // 5. Notification permission status
      try {
        _notificationPermissionStatus = await Permission.notification.status;
      } catch (e) {
        _notificationPermissionStatus = PermissionStatus.denied;
      }

      // 4. Exact Alarm permission status
      try {
        final notifService = ref.read(notificationServiceProvider);
        _exactAlarmStatus = await notifService.canScheduleExactAlarms();
      } catch (e) {
        _exactAlarmStatus = false;
      }

      // 5. Channels
      try {
        final notifService = ref.read(notificationServiceProvider);
        _channels = await notifService.getRegisteredChannels();
      } catch (_) {
        _channels = [];
      }

      // 6. FCM Token
      try {
        _fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        _fcmToken = 'Error: $e';
      }

      // 7. Subscribed topics from SharedPreferences + defaults
      final prefs = await SharedPreferences.getInstance();
      _isTestTopicEnabled = prefs.getBool(FcmService.testTopicEnabledKey) ?? false;

      final topics = <String>{FcmService.globalBroadcastTopic};
      if (_isTestTopicEnabled) {
        topics.add(FcmService.testNotificationTopic);
      }
      final teamTopics = prefs.getStringList('team_fcm_topics') ?? [];
      topics.addAll(teamTopics);

      final matchReminders = prefs.getStringList('match_reminders_storage') ?? [];
      for (final r in matchReminders) {
        try {
          final idMatch = RegExp(r'"matchId":\s*(\d+)').firstMatch(r);
          if (idMatch != null) {
            topics.add('match_${idMatch.group(1)}_events');
          }
        } catch (_) {}
      }
      _subscribedTopics = topics.toList();

      // 8. Pending scheduled reminders
      try {
        final notifService = ref.read(notificationServiceProvider);
        _pendingReminders = await notifService.getPendingNotificationRequests();
        _pendingRemindersCount = _pendingReminders.length;
      } catch (_) {
        _pendingRemindersCount = 0;
      }

      // 9. Fetch remote config document directly
      try {
        final doc = await FirebaseFirestore.instance.collection('config').doc('app_settings').get();
        _remoteConfigData = doc.data();
      } catch (e) {
        _remoteConfigData = {'error': e.toString()};
      }

      // 10. Run live collection test
      await _runCollectionTests();
    } catch (e) {
      debugPrint('[Diagnostics] Error collecting diagnostic data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _runCollectionTests() async {
    setState(() => _isTestingCollections = true);
    final results = <String, String>{};

    final collections = {
      'config/app_settings': () => FirebaseFirestore.instance.collection('config').doc('app_settings').get(),
      'sponsorships': () => FirebaseFirestore.instance.collection('sponsorships').limit(1).get(),
      'match_polls': () => FirebaseFirestore.instance.collection('match_polls').limit(1).get(),
      'match_streams': () => FirebaseFirestore.instance.collection('match_streams').limit(1).get(),
    };

    for (final entry in collections.entries) {
      try {
        final res = await entry.value();
        if (res is DocumentSnapshot) {
          results[entry.key] = res.exists ? '✅ متاح (مستند موجود)' : '⚠️ المستند غير منشأ بعد';
        } else if (res is QuerySnapshot) {
          results[entry.key] = '✅ متاح (${res.docs.length} مستند)';
        }
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied') {
          results[entry.key] = '🔒 محظور (permission-denied)';
        } else {
          results[entry.key] = '❌ خطأ Firebase (${fe.code})';
        }
      } catch (e) {
        results[entry.key] = '❌ خطأ: $e';
      }
    }

    if (mounted) {
      setState(() {
        _collectionTestResults = results;
        _isTestingCollections = false;
      });
    }
  }

  String _maskToken(String? token) {
    if (token == null || token.isEmpty) return 'غير متاح';
    if (token.startsWith('Error')) return token;
    if (token.length <= 10) return token;
    return '***...${token.substring(token.length - 8)}';
  }

  Future<void> _toggleTestTopic() async {
    final fcmService = ref.read(fcmServiceProvider);
    if (_isTestTopicEnabled) {
      await fcmService.disableTestNotificationTopic();
    } else {
      await fcmService.enableTestNotificationTopic();
    }
    await _loadAllDiagnostics();
  }

  Future<void> _sendLocalTestNotification() async {
    final notif = ref.read(notificationServiceProvider);
    await notif.showNotification(
      88888,
      '🧪 إشعار اختبار محلي',
      'تم إطلاق هذا الإشعار من شاشة تشخيص النظام بنجاح للتأكد من القنوات.',
      channelId: NotificationService.channelMatches,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إرسال إشعار اختباري محلي')),
    );
  }

  Future<void> _refreshSettings() async {
    final remoteService = ref.read(remoteConfigServiceProvider);
    await remoteService.fetchInitialConfig();
    await _loadAllDiagnostics();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الإعدادات عن بعد بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      appBar: AppBar(
        title: const Text('تشخيص النظام (Diagnostics)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'إعادة الفحص',
            onPressed: _loadAllDiagnostics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                // Environment & Package
                _buildSectionHeader('معلومات التطبيق و Firebase'),
                AppCard(
                  child: Column(
                    children: [
                      _buildInfoRow('اسم الحزمة', _packageName ?? '—'),
                      _buildDivider(border),
                      _buildInfoRow('إصدار التطبيق', _appVersion ?? '—'),
                      _buildDivider(border),
                      _buildInfoRow('معرف مشروع Firebase', _firebaseProjectId ?? '—'),
                      _buildDivider(border),
                      _buildInfoRow(
                        'حالة تشغيل Firebase',
                        _firebaseInitStatusText ?? '—',
                        isHighlighted: _firebaseInitReady,
                      ),
                      _buildDivider(border),
                      _buildInfoRow(
                        'مزامنة البيانات المعلقة (Pending Cloud Sync)',
                        _pendingSyncStatusText ?? '—',
                        isHighlighted: _isSyncClean,
                      ),
                      _buildDivider(border),
                      _buildInfoRow(
                        'حالة تسجيل الدخول (Auth UID)',
                        _authUid != null && _authUid!.length > 15
                            ? '***...${_authUid!.substring(_authUid!.length - 8)} (${_isAnonymous == true ? 'مجهول' : 'مسجل'})'
                            : (_authUid ?? '—'),
                        isHighlighted: _authUid != null && !_authUid!.contains('غير مسجل') && !_authUid!.contains('error'),
                      ),
                      _buildDivider(border),
                      _buildInfoRow(
                        'إذن الإشعارات (OS)',
                        _notificationPermissionStatus?.name ?? '—',
                        isHighlighted: _notificationPermissionStatus == PermissionStatus.granted,
                      ),
                      _buildDivider(border),
                      _buildInfoRow(
                        'إذن التنبيهات الدقيقة (Exact Alarm)',
                        _exactAlarmStatus == true ? 'مفعل (Granted)' : 'معطل أو غير متاح',
                        isHighlighted: _exactAlarmStatus == true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // FCM Registration & Topics
                _buildSectionHeader('Firebase Cloud Messaging (FCM)'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('رمز الجهاز (FCM Token)', style: AppTypography.caption(color: textMuted)),
                                const SizedBox(height: 4),
                                Text(
                                  _maskToken(_fcmToken),
                                  style: AppTypography.labelMedium().copyWith(fontFamily: 'monospace'),
                                ),
                              ],
                            ),
                          ),
                          if (_fcmToken != null && !_fcmToken!.startsWith('Error'))
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 20),
                              tooltip: 'نسخ الرمز الكامل',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _fcmToken!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم نسخ رمز FCM إلى الحافظة')),
                                );
                              },
                            ),
                        ],
                      ),
                      _buildDivider(border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('موضوع الاختبار (${FcmService.testNotificationTopic})', style: AppTypography.bodySmall()),
                          Switch.adaptive(
                            value: _isTestTopicEnabled,
                            onChanged: (_) => _toggleTestTopic(),
                          ),
                        ],
                      ),
                      _buildDivider(border),
                      Text('المواضيع المشترك بها حالياً (${_subscribedTopics.length}):', style: AppTypography.caption(color: textMuted)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _subscribedTopics.map((t) {
                          return Chip(
                            label: Text(t, style: const TextStyle(fontSize: 11)),
                            backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                            padding: EdgeInsets.zero,
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Live Collection Read Tests (Rules verification)
                _buildSectionHeader('اختبار قراءة مجموعات Firestore (قواعد الأمان)'),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('فحص الصلاحيات المباشر', style: AppTypography.titleSmall()),
                          if (_isTestingCollections)
                            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          else
                            TextButton.icon(
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('إعادة الفحص'),
                              onPressed: _runCollectionTests,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._collectionTestResults.entries.map((e) {
                        final isDenied = e.value.contains('permission-denied');
                        final isSuccess = e.value.contains('✅');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(e.key, style: AppTypography.bodySmall().copyWith(fontWeight: FontWeight.w600)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDenied
                                        ? Colors.redAccent
                                        : (isSuccess ? Colors.green : textMuted),
                                    fontWeight: isDenied || isSuccess ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // OS Notification Channels
                _buildSectionHeader('قنوات الإشعارات المسجلة في Android OS (${_channels?.length ?? 0})'),
                AppCard(
                  child: Column(
                    children: (_channels == null || _channels!.isEmpty)
                        ? [Text('لم يتم العثور على قنوات مسجلة', style: AppTypography.bodySmall(color: textMuted))]
                        : _channels!.map((ch) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.notifications_active_rounded, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${ch.name} (${ch.id})', style: AppTypography.bodySmall()),
                                  ),
                                  Text('أهمية: ${ch.importance.name}', style: AppTypography.caption(color: textMuted)),
                                ],
                              ),
                            );
                          }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Last 10 Messages Ring Buffer
                _buildSectionHeader('آخر الرسائل الواردة (${FcmService.recentMessages.length}/10)'),
                AppCard(
                  child: FcmService.recentMessages.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text('لم يتم استلام أي إشعارات أثناء تشغيل التطبيق بعد.', style: AppTypography.bodySmall(color: textMuted)),
                        )
                      : Column(
                          children: FcmService.recentMessages.map((msg) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                borderRadius: BorderRadius.circular(AppRadii.sm),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(msg.title, style: AppTypography.labelLarge()),
                                      Text(
                                        '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                        style: AppTypography.caption(color: textMuted),
                                      ),
                                    ],
                                  ),
                                  if (msg.body.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(msg.body, style: AppTypography.bodySmall()),
                                  ],
                                  if (msg.from != null) ...[
                                    const SizedBox(height: 2),
                                    Text('From: ${msg.from}', style: AppTypography.caption(color: textMuted)),
                                  ],
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Pending Reminders
                _buildSectionHeader('التذكيرات المجدولة بالهاتف (Pending Alarms: $_pendingRemindersCount)'),
                AppCard(
                  child: _pendingReminders.isEmpty
                      ? Text('لا توجد تذكيرات مجدولة حالياً.', style: AppTypography.bodySmall(color: textMuted))
                      : Column(
                          children: _pendingReminders.map((p) {
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.alarm, size: 18, color: AppColors.primary),
                              title: Text(p.title ?? 'بدون عنوان', style: AppTypography.bodySmall()),
                              subtitle: Text(p.body ?? '', style: AppTypography.caption(color: textMuted)),
                              trailing: Text('#${p.id}', style: AppTypography.caption(color: textMuted)),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Remote Config Snapshot
                _buildSectionHeader('بيانات config/app_settings المسحوبة'),
                AppCard(
                  child: _remoteConfigData == null
                      ? const Text('لا توجد بيانات')
                      : Text(
                          _remoteConfigData.toString(),
                          style: AppTypography.caption(color: textMuted).copyWith(fontFamily: 'monospace'),
                        ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action Buttons
                ElevatedButton.icon(
                  icon: const Icon(Icons.notifications_active_rounded),
                  label: const Text('إرسال إشعار تجريبي محلي فوري'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _sendLocalTestNotification,
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  icon: const Icon(Icons.cloud_sync_rounded),
                  label: const Text('تحديث الإعدادات عن بعد الآن (Refresh Settings)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _refreshSettings,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs, top: AppSpacing.sm),
      child: Text(title, style: AppTypography.titleSmall()),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTypography.bodySmall()),
          Text(
            value,
            style: AppTypography.labelMedium().copyWith(
              color: isHighlighted ? Colors.green : null,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color border) {
    return Divider(height: 1, thickness: 0.5, color: border);
  }
}
