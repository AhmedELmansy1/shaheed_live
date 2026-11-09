import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/sponsorship_model.dart';
import '../config/env_config.dart';

/// Service managing observation and metric tracking for Direct Sponsorships.
class SponsorshipService {
  final FirebaseFirestore? _explicitFirestore;
  final Set<String> _recordedImpressions = <String>{};

  SponsorshipService({FirebaseFirestore? firestore})
      : _explicitFirestore = firestore;

  FirebaseFirestore? get _firestore {
    if (_explicitFirestore != null) return _explicitFirestore;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Streams active sponsorship campaigns in real-time.
  /// Always emits empty list in Demo Mode to ensure safe portfolio degradation.
  Stream<List<SponsorshipCampaign>> streamActiveSponsorships() {
    if (EnvConfig.isDemoMode) {
      return Stream.value(const []);
    }

    final fs = _firestore;
    if (fs == null) return Stream.value(const []);

    return fs
        .collection('sponsorships')
        .where('enabled', isEqualTo: true)
        .snapshots()
        .map((snap) {
          final list = <SponsorshipCampaign>[];
          for (final doc in snap.docs) {
            try {
              final campaign = SponsorshipCampaign.fromMap(doc.data(), doc.id);
              if (campaign.isActive) {
                list.add(campaign);
              }
            } catch (e) {
              debugPrint('[SponsorshipService] Error parsing campaign ${doc.id}: $e');
            }
          }
          return list;
        })
        .handleError((err) {
          debugPrint('[SponsorshipService] Stream error: $err');
          return const <SponsorshipCampaign>[];
        });
  }

  /// Records a verified banner impression (+1) once per session per campaign.
  Future<void> recordImpression(String campaignId) async {
    if (EnvConfig.isDemoMode || campaignId.isEmpty) return;
    if (_recordedImpressions.contains(campaignId)) return;

    _recordedImpressions.add(campaignId);

    try {
      final fs = _firestore;
      if (fs == null) return;

      debugPrint('[SponsorshipService] Recording impression for campaign: $campaignId');
      await fs.collection('sponsorships').doc(campaignId).update({
        'impression_count': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('[SponsorshipService] Failed to record impression: $e');
    }
  }

  /// Records a user click (+1) and opens the target landing URL.
  Future<void> recordClickAndOpen(SponsorshipCampaign campaign) async {
    if (EnvConfig.isDemoMode) return;

    // 1. Increment click count asynchronously
    try {
      final fs = _firestore;
      if (fs != null) {
        debugPrint('[SponsorshipService] Recording click for campaign: ${campaign.id}');
        fs.collection('sponsorships').doc(campaign.id).update({
          'click_count': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('[SponsorshipService] Failed to record click: $e');
    }

    // 2. Open click URL
    if (campaign.clickUrl.isNotEmpty) {
      try {
        final uri = Uri.parse(campaign.clickUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        debugPrint('[SponsorshipService] Failed to launch clickUrl: $e');
      }
    }
  }
}

final sponsorshipServiceProvider = Provider<SponsorshipService>((ref) {
  return SponsorshipService();
});

/// StreamProvider of all currently active sponsorships.
final activeSponsorshipsStreamProvider =
    StreamProvider<List<SponsorshipCampaign>>((ref) {
  final service = ref.watch(sponsorshipServiceProvider);
  return service.streamActiveSponsorships();
});

/// Specific placement provider.
final sponsorshipByPlacementProvider =
    Provider.family<SponsorshipCampaign?, SponsorshipPlacement>((ref, placement) {
  final listAsync = ref.watch(activeSponsorshipsStreamProvider);
  final list = listAsync.value ?? const [];
  try {
    return list.firstWhere((c) => c.placement == placement);
  } catch (_) {
    return null;
  }
});

