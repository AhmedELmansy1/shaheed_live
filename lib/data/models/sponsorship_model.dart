/// Placement targets for direct sponsorships.
enum SponsorshipPlacement {
  homeTopBanner,
  matchDetailsTop,
  popupDialog,
  nativeList;

  static SponsorshipPlacement fromString(String? val) {
    switch (val?.trim().toLowerCase()) {
      case 'match_details_top':
      case 'banner_match':
      case 'match':
        return SponsorshipPlacement.matchDetailsTop;
      case 'popup_dialog':
      case 'popup':
        return SponsorshipPlacement.popupDialog;
      case 'native_list':
      case 'native':
      case 'list':
        return SponsorshipPlacement.nativeList;
      case 'home_top_banner':
      case 'banner_home':
      case 'home':
      default:
        return SponsorshipPlacement.homeTopBanner;
    }
  }

  String get key {
    switch (this) {
      case SponsorshipPlacement.matchDetailsTop:
        return 'match_details_top';
      case SponsorshipPlacement.popupDialog:
        return 'popup_dialog';
      case SponsorshipPlacement.nativeList:
        return 'native_list';
      case SponsorshipPlacement.homeTopBanner:
        return 'home_top_banner';
    }
  }
}

/// Data model representing a direct sponsorship campaign.
class SponsorshipCampaign {
  final String id;
  final String title;
  final String sponsorName;
  final String bannerUrl;
  final String clickUrl;
  final SponsorshipPlacement placement;
  final String startDate;
  final String endDate;
  final int impressionCount;
  final int clickCount;
  final bool enabled;

  const SponsorshipCampaign({
    required this.id,
    required this.title,
    required this.sponsorName,
    required this.bannerUrl,
    required this.clickUrl,
    required this.placement,
    this.startDate = '',
    this.endDate = '',
    this.impressionCount = 0,
    this.clickCount = 0,
    this.enabled = true,
  });

  /// Evaluates whether this campaign is currently active based on date range and enabled toggle.
  bool get isActive {
    if (!enabled) return false;
    if (bannerUrl.trim().isEmpty) return false;

    if (startDate.isEmpty && endDate.isEmpty) return true;

    final today = DateTime.now().toIso8601String().split('T')[0];
    if (startDate.isNotEmpty && today.compareTo(startDate) < 0) return false;
    if (endDate.isNotEmpty && today.compareTo(endDate) > 0) return false;

    return true;
  }

  factory SponsorshipCampaign.fromMap(Map<String, dynamic> map, [String docId = '']) {
    int parseNum(dynamic val) {
      if (val is num) return val.toInt();
      return int.tryParse(val?.toString() ?? '') ?? 0;
    }

    return SponsorshipCampaign(
      id: docId,
      title: (map['title'] as String?)?.trim() ?? 'حملة إعلانية',
      sponsorName: (map['sponsor_name'] as String?)?.trim() ?? 'الراعي الرسمي',
      bannerUrl: (map['banner_url'] as String?)?.trim() ??
          (map['image_url'] as String?)?.trim() ??
          '',
      clickUrl: (map['click_url'] as String?)?.trim() ??
          (map['target_url'] as String?)?.trim() ??
          '',
      placement: SponsorshipPlacement.fromString(map['placement'] as String?),
      startDate: (map['start_date'] as String?)?.trim() ?? '',
      endDate: (map['end_date'] as String?)?.trim() ?? '',
      impressionCount: parseNum(map['impression_count']),
      clickCount: parseNum(map['click_count']),
      enabled: (map['enabled'] as bool?) ?? (map['is_active'] as bool?) ?? true,
    );
  }
}

