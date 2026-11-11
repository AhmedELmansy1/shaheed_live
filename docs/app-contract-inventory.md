# Shoot Live — Full App Contract Inventory & Architecture Audit

**Branch**: `fix/contract-and-time`  
**Workspace**: `d:\My_Project\shoot_live`  
**Dashboard (Read-Only)**: `D:\My_Project\shoot_live_dashboard`  
**Date**: November 11, 2026  

---

## 1. Screens & Features Inventory

| Screen / Feature | Route | Purpose | Data Sources | Gating Flags / Guards |
| :--- | :--- | :--- | :--- | :--- |
| **Home (الرئيسية)** | `/home` | Displays today's matches, hero featured match, date selector tabs, live TV strip, urgent ticker, and sponsor banners. | `MatchesRepository` (`matches_by_date`), `RemoteConfigService` (`config/app_settings`), `TvChannelsRepository`, `SponsorshipService`. | Requires notifications setup & onboarding completed (`app_router.dart:225-242`). |
| **Leagues (البطولات)** | `/leagues` | Displays curated and grouped competitions, standings, and league matches. | `OnboardingRepository` (`type=leagues`), `MatchesRepository`. | None. |
| **Live TV Channels (القنوات)** | `/channels` | Live TV broadcast directory for sports channels (beIN, SSC, Abu Dhabi Sports, ON Time). | `TvChannelsRepository` (`tv_channels` Firestore collection + local SharedPreferences cache). | None. |
| **Settings (الإعدادات)** | `/settings` | User preferences, notification sound picker, favorite teams/leagues management, developer info, cache clear. | `SharedPreferences`, `RemoteConfigService`, `UserSyncService`. | None. |
| **Match Details (تفاصيل المباراة)** | `/match/:id` | Scoreboard, stream player/servers, live commentary, events timeline, lineups, head-to-head stats, and voting poll. | `MatchesRepository` (`match_info`, `statics_match`, `matches_event`, `matches_lineup`), `MatchStreamRepository` (`match_streams/{id}`), `PollService` (`match_polls/{id}`). | Stream player tab gated by `ENABLE_STREAMING` flag (`kEnableStreaming`). |
| **League Details (تفاصيل البطولة)** | `/league/:id` | League standings table, fixtures, top scorers, and tournament rules. | `OnboardingRepository`, `MatchesRepository`. | None. |
| **Team Search (البحث)** | `/search` | Instant search for clubs and national teams across leagues. | `OnboardingRepository` (`type=teams`), local cache. | None. |
| **Team Fixtures (مباريات الفريق)** | `/team/:name/fixtures`| Past and upcoming fixtures for a specific team. | `MatchesRepository` (`matches_by_date`). | None. |
| **Favorite Teams (الفرق المفضلة)** | `/favorites` | Manage user's favorite clubs with FCM notification toggles. | `SharedPreferences`, `UserSyncService` (`users/{uid}`). | None. |
| **Force Update (تحديث إجباري)** | `/force-update` | Hard-blocks deprecated app versions; displays changelog and direct APK download link. | `RemoteConfigService` (`config/app_settings` -> `min_supported_version`, `force_update`). | Activated by `appUpdateInfoProvider.isHardBlocked` (`app_router.dart:206`). |
| **Onboarding: Notifications** | `/onboarding/notifications`| Prompts user for system notification permissions (POST_NOTIFICATIONS) and explanation. | `SharedPreferences`, `NotificationService`. | First run if `!hasCompletedNotificationSetup`. |
| **Onboarding: Leagues** | `/onboarding/leagues` | Wizard to select preferred leagues. | `OnboardingRepository` (`type=leagues`). | First run if `!hasCompletedOnboarding`. |
| **Onboarding: Teams** | `/onboarding/teams` | Wizard to select favorite teams within chosen leagues. | `OnboardingRepository` (`type=teams&league_id=`). | First run if `!hasCompletedOnboarding`. |
| **Settings: Manage Leagues** | `/settings/leagues` | Re-open league selector to update followed leagues. | `OnboardingRepository`, `UserSyncService`. | None. |
| **Diagnostics (التشخيص)** | `/diagnostics` | Developer diagnostics dashboard: API status, FCM token, timezone, cached keys, poll latency, battery optimization. | `DiagnosticsService`, `TimezoneHelper`, `DioClient`. | Gated by `--dart-define=ENABLE_DIAGNOSTICS=true` (`app_router.dart:175`). |
| **Design Gallery** | `/design-gallery` | Design token test harness and widget showcase. | Local theme tokens (`AppColors`, `AppTheme`). | Gated by `--dart-define=ENABLE_DIAGNOSTICS=true` (`app_router.dart:188`). |

---

## 2. Firestore Collections & Document Paths

| Path | R/W | Mechanism | Exact Fields & Types | Defaults on Missing | File:Line | Error Handling |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `config/app_settings` | Read | `snapshots()` live stream + `get()` fallback | `ad_config: Map`<br>- `enabled: bool`<br>- `banner_ad_unit_id: string`<br>- `interstitial_ad_unit_id: string`<br>- `interstitial_interval_clicks: int`<br>`theme_config: Map`<br>- `active_preset: string`<br>- `primary_color: string`<br>- `accent_color: string`<br>- `kickoff_offset_hours: int`<br>`ticker_config: Map`<br>- `is_enabled: bool`<br>- `text: string`<br>- `speed_seconds: int`<br>- `is_urgent: bool`<br>- `action_url: string`<br>`latest_app_version: string`<br>`min_supported_version: string`<br>`force_update: bool`<br>`update_download_url: string`<br>`api_base_url_override: string?`<br>`latest_notification: Map` | `RemoteConfigModel.fallback()`: AdMob enabled with test IDs; offset `0`; ticker disabled; min version `1.0.0`; download url `'https://shootlive.app'`. | `lib/core/services/remote_config_service.dart:45-120` | Catches exceptions, yields cached or static fallback model, app runs without crashing. |
| `match_streams/{matchId}` | Read | `snapshots()` live stream + `get()` | `is_stream_enabled: bool`<br>`servers: List<Map>` (`id: string`, `name: string`, `url: string`, `type: string`, `quality: string`, `priority: int`, `is_active: bool`, `headers: Map`, `status: string`)<br>`updated_at: Timestamp\|string` | `is_stream_enabled: false`, `servers: []` | `lib/data/repositories/match_stream_repository.dart:35-95` | Returns `null`, UI shows "لا توجد سيرفرات بث متاحة حالياً". |
| `match_polls/{matchId}` | Read | `snapshots()` live stream | `question: string`<br>`options: List<Map>` (`id: string`, `label: string`, `votes: int`)<br>`total_votes: int`<br>`enabled: bool` | `question: 'من تتوقع أن يفوز؟'`, `options: []`, `total_votes: 0`, `enabled: true` | `lib/core/services/poll_service.dart:100-155` | Falls back to default 3 options (Home, Draw, Away). |
| `match_polls/{matchId}/votes/{uid}` | Read | `snapshots()` live stream | `option_id: string`<br>`created_at: Timestamp` | `null` (user has not voted yet) | `lib/core/services/poll_service.dart:125-148` | If not found, user is allowed to vote. Direct client writes forbidden by rules (written via `POST /api/polls/vote`). |
| `sponsorships/{campaignId}` | Read / Update | `collection.where('is_active', true).snapshots()` | `id: string`<br>`title: string`<br>`image_url: string`<br>`target_url: string`<br>`placement: string`<br>`start_date: string`<br>`end_date: string`<br>`is_active: bool`<br>`impression_count: int`<br>`click_count: int` | `is_active: false`, counters `0` | `lib/core/services/sponsorship_service.dart:40-110` | Counter increments use `FieldValue.increment(1)`. Catches errors silently to prevent UI disruption. |
| `stream_reports/{reportId}` | Create | `collection('stream_reports').doc(id).set()` | `reportId`: `{uid}_{match_id}_{issue_type}`<br>`user_id: string`<br>`match_id: int/string`<br>`match_title: string`<br>`server_id: string`<br>`server_name: string`<br>`issue_type: string`<br>`user_comment: string`<br>`status: 'pending'`<br>`created_at: serverTimestamp()` | None (required fields validated) | `lib/core/services/stream_report_service.dart:65-115` | Validated against whitelist; duplicate reports or unauthenticated submissions return clean user error. |
| `users/{uid}` | Read / Write | `doc(uid).get()` & `set(..., SetOptions(merge: true))` | `selected_leagues: List`<br>`selected_teams: List`<br>`updated_at: serverTimestamp()` | Empty lists | `lib/core/services/user_sync_service.dart:45-90` | If unauthenticated or offline, preferences persist in `SharedPreferences`. |
| `tv_channels/{channelId}` | Read | `snapshots()` live stream + `get()` | `name: string`<br>`logo_url: string`<br>`default_stream_url: string` (or `stream_url`)<br>`default_player_type: string`<br>`default_quality: string`<br>`is_active: bool`<br>`order: int` | Defaults to `TvChannelModel.defaultChannels` (beIN 1, beIN 2, SSC 1, Abu Dhabi 1). | `lib/data/repositories/tv_channels_repository.dart:78-140` | Yields cached SharedPreferences channels first; on permission-denied / network error keeps cache. |

---

## 3. HTTP Endpoints Inventory

**Base URL**: Configured in `EnvConfig.baseApiUrl` (`defaultBaseApiUrl = 'https://shoot-live-admin-dashboard.vercel.app/api/matches'`), dynamically overridable by `RemoteConfigModel.apiBaseUrlOverride`.  
**Dashboard URL**: `EnvConfig.dashboardBaseUrl` (`'https://shoot-live-admin-dashboard.vercel.app'`).  
**Headers**: `Accept: application/json`, `User-Agent: ShootLive/1.0.0 (Android)`.  

| Method | Endpoint & Parameters | Purpose | Response Keys Read | Error & Status Handling |
| :--- | :--- | :--- | :--- | :--- |
| `GET` | `/api/matches?type=matches_by_date&date={YYYY-MM-DD}` | Main schedule feed for a specific calendar day. | `data[]` or `matches[]`: `match_id`, `match_date`, `match_time`, `status`, `event_status`, `status_text`, `home_scores`, `away_scores`, `championship`, `home_team`, `away_team`, `admin_title`, `live`. | Returns empty list if no matches; retries once on network failure; throws `ApiException`. |
| `GET` | `/api/matches?type=matches_today` | Server-bucketed today's matches. | Same as `matches_by_date`. | Same. |
| `GET` | `/api/matches?type=matches_tomorrow` | Server-bucketed tomorrow's matches. | Same as `matches_by_date`. | Same. |
| `GET` | `/api/matches?type=matches_yesterday`| Server-bucketed yesterday's matches. | Same as `matches_by_date`. | Same. |
| `GET` | `/api/matches?type=match_info&id={matchId}` | Metadata: stadium, referee, channel, commentator, team recent form. | `data`: `match_id`, `stadium_name`, `channel_name`, `commentator_name`, `referee_name`, `home_form`, `away_form`. | Returns `null` if unparsable; UI shows placeholder metadata. |
| `GET` | `/api/matches?type=statics_match&id={matchId}` | Head-to-head match statistics. | `data`: possession, total shots, shots on target, corners, fouls, offsides, yellow/red cards, saves. | Parsed defensively; missing stats display `0%` or `-`. |
| `GET` | `/api/matches?type=matches_event&id={matchId}` | Match events timeline. | `data.events[]`: `event_id`, `type`, `time_minute`, `time_plus`, `team_id`, `player_name`, `assist_player_name`. | Empty list for upcoming matches; timeline displays "لا توجد أحداث مسجلة بعد". |
| `GET` | `/api/matches?type=matches_lineup&id={matchId}` | Starting lineups, formations, substitutes, coaches. | `data`: `formation`, `lineup[]`, `substitutes[]`, `coach`. | Returns `null` if lineup not yet announced; UI shows "التشكيلة غير متوفرة بعد". |
| `GET` | `/api/matches?type=leagues` | Competitions catalog. | `data[]` or `leagues[]`: `id`, `title`, `image` / `logo`, `country`. | Reads disk cache if network fails; throws `CatalogException` if both fail. |
| `GET` | `/api/matches?type=teams` | Full teams catalog. | `data[]` or `teams[]`: `row_id`, `title`, `image`. | Cached locally in SharedPreferences. |
| `GET` | `/api/matches?type=teams&league_id={id}`| Teams in specific league. | `data[]` or `teams[]`: `row_id`, `title`, `image`. | Cached per league ID. |
| `POST`| `/api/polls/vote` | Cast user vote for match poll. | Header: `Authorization: Bearer <ID_TOKEN>`. Body: `{ match_id, option_id }`. Response: `{ success, poll: { ... } }`. | `200` -> Success; `409` -> Already voted; `401` -> Refresh token & retry; `429` -> Rate limited. |
| `GET` | `/api/channels` | Admin server-side channels catalog. | `channels[]`: `id`, `name`, `logo_url`, `default_stream_url`, `default_player_type`, `default_quality`, `is_active`, `order`. | Bypasses client Firestore rules; falls back to Firestore `tv_channels`. |

---

## 4. Firebase Cloud Messaging (FCM) Inventory

- **Topics**:
  - `all`: Global broadcast topic for urgent announcements and global match notifications (`FcmService.globalBroadcastTopic`, `lib/core/services/fcm_service.dart:43`).
  - `match_{matchId}`: Specific match reminders & live goal/event subscriptions (`MatchReminderService.dart:409`).
  - `team_{teamId}`: Favorite team updates (`MatchReminderService.dart:587`).
  - `match_score_test_notifications`: Isolated test topic for diagnostic verification (`fcm_service.dart:47`).
- **Notification Channels (Android)**:
  - `matches_channel_v2`: Match start reminders & general announcements (`Importance.max`, priority high).
  - `match_reminders_v2`: Scheduled countdown alarms (15 min / 1 hour before kickoff).
  - `live_events_v2`: Default goal & red card alerts (standard sound).
  - `live_events_whistle_v2`: Goal alerts with referee whistle sound (`whistle.mp3`).
  - `live_events_cheer_v2`: Goal alerts with stadium crowd cheer sound (`cheer.mp3`).
- **Payload Keys Handled**:
  - `data['event_type']`: `'goal'`, `'penalty'`, `'penalty_scored'`, `'penalty_missed'`, `'red_card'`, `'kickoff'`, `'fulltime'`, `'reminder_1hr'`, `'reminder_15min'`, `'production_verification'`.
  - `data['match_id']`, `data['home']`, `data['away']`, `data['home_score']`, `data['away_score']`, `data['scorer']`, `data['player']`.
- **Foreground / Background / Terminated**:
  - Foreground: `FirebaseMessaging.onMessage` passes to `FcmService.handleForegroundMessage()`, creates heads-up banner via `FlutterLocalNotificationsPlugin`.
  - Background / Terminated: Handled by top-level `@pragma('vm:entry-point') backgroundMessageHandler` in `firebase_ready_provider.dart:25-50`.
  - Notification tap: `NotificationService.onMatchNotificationTap` pushes `/match/:id`. Cold starts hold `pendingColdStartMatchId`.
- **User Preference Gating**:
  - `pref_notify_match_start` (bool, default `true`): Suppresses kickoff / reminder notifications if false (`fcm_service.dart:279`).
  - `pref_notify_goal_alerts` (bool, default `true`): Suppresses live goal / penalty notifications if false (`fcm_service.dart:283`).

---

## 5. Deep Links & Share Links

- **Supported Incoming Schemes & URIs**:
  - `shootlive://match/{id}` (`AndroidManifest.xml:41-46`, `deep_link_handler.dart:22`).
  - `shootlive://match?id={id}`
  - `https://shootlive.app/match/{id}`
  - `https://shootlive.app/match?id={id}`
- **Generated Share Text**:
  - Generated by `MatchShareHelper.shareMatch(match)` (`lib/core/utils/match_share_helper.dart:10-44`).
  - Pre-match: `⏰ مباراة {home} × {away} تبدأ {matchTime} | {league} | عبر تطبيق شوت لايف`.
  - Live: `🔴 مباشر الآن: {home} {homeScore}-{awayScore} {away} - الدقيقة {minute} | {league} | عبر تطبيق شوت لايف`.
  - Finished: `⚽ النتيجة النهائية: {home} {homeScore}-{awayScore} {away} | {league} | عبر تطبيق شوت لايف`.

---

## 6. Hardcoded Values & Remote Controllability Audit

| Item | Current Location | Value | Recommendation |
| :--- | :--- | :--- | :--- |
| **Source Timezone** | `ApiConfig.sourceTimezone` (`match_score_api.dart:41`) | `'Africa/Cairo'` | Centralized; keep in `KickoffTime.sourceTimezone`. |
| **Popular Leagues Order** | `PopularLeaguesConfig.orderedIds` (`popular_leagues_config.dart:18`) | Fixed list of 17 league IDs (Egyptian, Premier League, LaLiga, UCL, Saudi, etc.) | Expose in `config/app_settings` under `popular_leagues: []`. |
| **Privacy Policy URL** | `settings_screen.dart:865` | `'https://shootlive.app/privacy'` | Add to `config/app_settings` -> `privacy_policy_url`. |
| **Terms of Service URL**| `settings_screen.dart:886` | `'https://shootlive.app/terms'` | Add to `config/app_settings` -> `terms_url`. |
| **Developer Profiles** | `developer_profile.dart:280` | WhatsApp, LinkedIn, GitHub URLs | Hardcoded developer links. |
| **Cache TTLs** | `matches_cache_service.dart:15` | Matches today: 60s; details: 120s; leagues: 7 days. | Sufficient; can be tuned via remote config if needed. |
| **Ad Interval Clicks** | `RemoteConfigModel.dart:28` | Default `3` clicks between interstitials | Already remotely controllable via `ad_config.interstitial_interval_clicks`. |

---

## 7. Time Handling Audit Across All Surfaces

| File & Line | Surface | Assumed Timezone | Offset Handling | Midnight Shift Issue? | Countdown Consistency |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `date_formatter.dart:66-120` | `formatMatchTime` | `Africa/Cairo` via IANA db | Adds `globalKickoffOffsetHours` clamped `[-3, 3]`. | Handled via `tz.TZDateTime.toLocal()`, but ad-hoc offset addition directly shifted local DateTime. | Does not compute countdown. |
| `date_formatter.dart:127-160` | `parseCairoMatchDateTime` | `Africa/Cairo` | Same offset logic as `formatMatchTime`. | Same. | Inconsistent with `KickoffTime.parse`. |
| `date_formatter.dart:167-200` | `formatRemainingKickoff` | Local `DateTime` | Relies on passed DateTime. | Safe if input is UTC instant. | Uses local `DateTime.now()`. |
| `match_score_api.dart:109-150` | `KickoffTime.parse` & `minutesSinceKickoff` | `Africa/Cairo` | Did NOT accept admin offset; failed on 12h Arabic meridiem (`04:00 م`). | Broke on Arabic time strings; failed to add +12h for PM. | Mismatched with `formatMatchTime`. |
| `match_score_api.dart:225-238` | `MatchStatusResolver.resolve` | `Africa/Cairo` | Evaluated `minutesSinceKickoff > 180` to force `finished`. | **ROOT CAUSE BUG**: Unscheduled (`00:00:00`) or PM matches parsed as AM exceeded 180 min and became "انتهت" with 0:0! | Directly corrupted match status! |
| `match_reminder_service.dart:695-730` | `_computeKickoffTime` | `Africa/Cairo` | Ignored `globalKickoffOffsetHours`; threw on meridiem strings (`time.split(':')`). | Reminder fired at wrong time when offset was set. | Mismatched with card display. |
| `hero_match_card.dart:288` | Hero Match Card | Calls `match.formattedLocalTime` | Follows `DateFormatter.globalKickoffOffsetHours`. | Safe. | Uses `match.remainingTimeUntilKickoff`. |
| `match_card.dart:377` | Match Card | Calls `match.formattedLocalTime` | Follows `DateFormatter.globalKickoffOffsetHours`. | Safe. | Uses `match.remainingTimeUntilKickoff`. |
| `match_details_screen.dart:462` | Match Details Header | Calls `match.formattedLocalTime` | Follows `DateFormatter.globalKickoffOffsetHours`. | Safe. | Follows `formattedLocalTime`. |

---

## 8. Dashboard-Expectation Gaps & Contract Change Proposals

| Feature | What Dashboard Writes / Provides | What App Expects / Reads | Root Cause Gap & Status | Safe Resolution |
| :--- | :--- | :--- | :--- | :--- |
| **TV Channels Fields** | Dashboard writes `name`, `logo_url`, `default_stream_url`, `default_player_type`, `default_quality`, `is_active`, `order` (`D:\My_Project\shoot_live_dashboard\src\lib\channelService.ts:115-123`). | App's `TvChannelModel` previously checked `default_stream_url`, but some repos used `stream_url`. | Field naming discrepancy. | `TvChannelModel.fromMap` supports `default_stream_url`, falling back to `stream_url` and `url`. |
| **TV Channels Permissions** | Dashboard writes via client SDK fallback (`setDoc(doc(db, 'tv_channels', id))`) if Admin route fails. | Firestore rules require `isAdmin()` custom claim (`firestore.rules:94`). Admin emails alone do not satisfy client rules without `{ admin: true }`. | User saw `Missing or insufficient permissions` on dashboard when Admin token had no custom claim. | App-side reads are public (`allow read: if true;`); dashboard should rely on `/api/channels` (Admin SDK) rather than client Firestore. |
| **Match Time Format** | Worker API feed delivers `match_time` in Egyptian time (`Africa/Cairo`), sometimes in 12h without meridiem or 24h. | App expected clean 24h `HH:mm:ss` or 12h with meridiem. | Dropped meridiem turned 8:00 PM (`20:00`) into 8:00 AM (`08:00`), causing elapsed calculation > 180 min to mark unplayed matches as "انتهت" (finished). | Centralize in `KickoffTime`: parse `Africa/Cairo` with full meridiem support, treat `00:00:00` as unscheduled TBD (never finished), and convert to device local timezone. |
| **Theme & Kickoff Offset** | Dashboard writes `theme_config.kickoff_offset_hours` (integer `-3` to `+3`). | App reads `theme_config` stream in `RemoteConfigService` and sets `DateFormatter.globalKickoffOffsetHours`. | Fully compatible. App clamps to `[-3, +3]`. Day bucketing preserved. | Centralize kickoff time resolution so admin offset is applied uniformly to cards, reminders, and countdowns. |
| **FCM Notifications Broadcast** | Dashboard sends via `/api/notifications/send` to topic `all` AND writes to `config/app_settings.latest_notification`. | App listens to topic `all` via FCM AND listens to `config/app_settings.latest_notification` for dual delivery. | Working as designed. Duplicate prevention via `last_seen_firestore_notif_id`. | Documented and verified. |
| **Polls Voting** | Dashboard provides server endpoint `POST /api/polls/vote` (Admin SDK transaction). | App routes all votes via `POST /api/polls/vote` with Firebase Auth Bearer token. | Direct client writes are forbidden by Firestore rules (`firestore.rules:41`). Server-side voting is mandatory. | Fully working. Defensive error handling in `PollService`. |

