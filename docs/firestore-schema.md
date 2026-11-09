# Firestore Schema & Client-Backend Contract

This document specifies the exact contract between the **Shoot Live Dashboard** (`D:\My_Project\shoot_live_dashboard`) and the **Shoot Live Flutter Mobile App** (`D:\My_Project\shoot_live`).

---

## 1. Remote App Configuration & Seasonal Themes (`config/app_settings`)

- **Firestore Document**: `config/app_settings`
- **Client Access**: Public Read-Only (`allow read: if true; allow write: if isAdmin();`)
- **Root Fields**:
  - `latest_app_version` (`string`): e.g. `"1.0.0"`
  - `min_supported_version` (`string`): e.g. `"1.0.0"`
  - `force_update` (`boolean`): Mandatory update flag
  - `update_download_url` (`string`): Direct APK or store download URL
  - `api_base_url_override` (`string`): Dynamic API gateway override URL
  - `ad_config` (`map`): AdMob placement toggles and ad unit IDs
  - `ticker_config` (`map`): Urgent announcement / breaking news ticker
  - `theme_config` (`map`): **Seasonal theme and kickoff offset configuration** (see below)
  - `updated_at` (`Timestamp`): Last modification timestamp

### `theme_config` Nested Map
> [!IMPORTANT]
> **Audit Finding**: `kickoff_offset_hours` is stored **INSIDE `theme_config`** (`config/app_settings.theme_config.kickoff_offset_hours`), NOT at the root of `app_settings`.
> The Flutter app parser inspects `data['theme_config']['kickoff_offset_hours']` with fallback to `data['kickoff_offset_hours']` and clamps the value to `[-3, +3]`.

| Field Name | Type | Allowed Values / Format | Description |
|---|---|---|---|
| `active_preset` | `string` | `'default_dark'`, `'ramadan'`, `'champions_league'`, `'classico'`, `'golden'` | Active UI theme preset |
| `primary_color` | `string` | Hex string, e.g. `"#10b981"` | Primary theme color token |
| `accent_color` | `string` | Hex string, e.g. `"#f59e0b"` | Accent / highlight color token |
| `banner_url` | `string` | URL or empty string `""` | Optional seasonal banner image URL |
| `enabled` | `boolean` | `true` / `false` | Whether remote theme override is active |
| `kickoff_offset_hours` | `number` (int) | `-3` to `+3` (default `0`) | Timezone / DST kickoff hour shift |
| `updated_at` | `Timestamp` | Firestore Timestamp | Last time theme was updated |

---

## 2. Match Polls (`match_polls`) & Server-Side Voting (`POST /api/polls/vote`)

- **Collection**: `match_polls`
- **Document ID**: `String(match_id)` (e.g. `"5795507"`)
- **Dashboard Service**: `src/lib/pollService.ts`
- **Security Posture**: **Zero Client Writes**. All writes from mobile clients are blocked by Firestore rules. Voting is performed strictly server-side via the Next.js API route `POST /api/polls/vote`.

### Document Schema
| Field Name | Type | Description |
|---|---|---|
| `match_id` | `string` | Associated match identifier |
| `question` | `string` | Poll question (e.g. `"من تتوقع أن يفوز بمباراة اليوم؟"`) |
| `options` | `Array<Option>` | Array of voting options |
| `total_votes` | `number` | Total votes recorded across all options |
| `enabled` | `boolean` | Poll visibility toggle |
| `created_at` | `Timestamp \| null` | Creation timestamp |
| `updated_at` | `Timestamp \| null` | Last updated timestamp |

#### `Option` Schema:
```json
{
  "id": "opt_1",
  "label": "ريال مدريد",
  "votes": 142
}
```

### Server Endpoint Contract: `POST /api/polls/vote`
- **URL**: `https://<dashboard-domain>/api/polls/vote` (configured via `--dart-define=DASHBOARD_BASE_URL` or fallback)
- **Headers**:
  - `Authorization`: `Bearer <Firebase_ID_Token>` (retrieved via `FirebaseAuth.instance.currentUser?.getIdToken()`)
  - `Content-Type`: `application/json`
- **Request Body**:
  ```json
  {
    "match_id": "5795507",
    "option_id": "opt_1"
  }
  ```
- **Server Execution Logic (Single Firestore Transaction)**:
  1. Authenticates user UID via `firebase-admin` `auth().verifyIdToken(token)`.
  2. Applies light sliding-window rate limiting: max 10 requests / minute per IP / UID.
  3. Executes `db.runTransaction`:
     - Reads `match_polls/{matchId}`: ensures document exists and `enabled === true`.
     - Verifies `option_id` exists in `options` array.
     - Checks `match_polls/{matchId}/votes/{uid}` receipt: throws error `ALREADY_VOTED` if it exists.
     - Writes `match_polls/{matchId}/votes/{uid}` with `{ option_id, voted_at: serverTimestamp() }`.
     - Atomically increments target option's `votes` and the poll's `total_votes`.
     - Updates `updated_at: serverTimestamp()`.
  4. Returns updated poll data `{ success: true, poll: { ... } }`.

### Subcollection Receipt: `match_polls/{matchId}/votes/{userId}`
- **Security Rule**: Read-only for the owning user (`request.auth.uid == userId`). Client write is `false` (`isAdmin()` only).

### Environment Variable Setup for Vercel:
To power `POST /api/polls/vote`, Vercel requires:
1. Go to **Firebase Console** -> **Project Settings** -> **Service accounts** tab.
2. Click **Generate new private key** (downloads a `.json` key file).
3. In **Vercel Dashboard** -> **Project Settings** -> **Environment Variables**:
   - Key: `FIREBASE_SERVICE_ACCOUNT_KEY`
   - Value: Paste the complete JSON string (e.g. `{"type":"service_account","project_id":"...","private_key":"..."}`).
   - Environments: Production, Preview, Development.
4. *Note*: Never commit this JSON file to git.

---

## 3. Direct Sponsorships (`sponsorships`)

- **Collection**: `sponsorships`
- **Document ID**: Unique Campaign ID (`string`)
- **Dashboard Service**: `src/lib/sponsorshipService.ts`

### Document Schema
| Field Name | Type | Description |
|---|---|---|
| `id` | `string` | Campaign ID (matches doc id) |
| `title` | `string` | Campaign title (e.g. `"عرض خاص لمتابعي شوت لايف"`) |
| `sponsor_name` | `string` | Name of sponsor (e.g. `"STC Pay"`) |
| `banner_url` | `string` | Direct image URL for banner |
| `click_url` | `string` | Destination landing page or deep-link |
| `placement` | `string` | `home_top_banner`, `match_details_top`, `popup_dialog`, `native_list` |
| `start_date` | `string` | `"YYYY-MM-DD"` start date |
| `end_date` | `string` | `"YYYY-MM-DD"` end date |
| `impression_count` | `number` | Total impressions recorded |
| `click_count` | `number` | Total user clicks recorded |
| `enabled` | `boolean` | Global campaign activation switch |
| `created_at` | `Timestamp \| null` | Creation timestamp |
| `updated_at` | `Timestamp \| null` | Last modification timestamp |

### Client Tracking & Security Rules:
- **Client Permissions**:
  - Update allowed **ONLY** for signed-in users (`request.auth != null`).
  - Affected keys strictly restricted to `['impression_count', 'click_count']`.
  - Increments only: values can never decrease (`>= resource.data`).
  - Total delta per update must be $\le 1$.
- **Impression Verification**: 50% visible in viewport for $\ge 1.0$s (debounced once per session).
- **Click Verification**: Counted on user tap prior to launching external browser.

> [!WARNING]
> ### Disclaimer: Approximate vs. Billing-Grade Tracking
> Client-side Firestore increments are **approximate counters** suitable for internal reporting, analytics, and operational pacing. They are **NOT billing-grade** because:
> 1. Compromised or rooted clients could forge increments within the rule constraints.
> 2. Network drops or offline queues may result in dropped or delayed events.
>
> **Recommended Server-Side Billing-Grade Architecture (Phase 3 Follow-Up)**:
> - Route clicks through a signed redirect proxy (e.g. `GET /api/sponsors/click?cid=...&sig=...&nonce=...`).
> - Route impressions through server-side 1x1 tracking beacon or Edge Worker with Cloudflare Turnstile bot-detection.
> - Store raw append-only audit events in BigQuery / Cloud Storage with IP deduplication and fraud scoring.

---

## 4. Stream Issue Reports (`stream_reports`)

- **Collection**: `stream_reports`
- **Document ID**: Deterministic `${uid}_${match_id}_${issue_type}`
- **Dashboard Service**: `src/lib/reportService.ts`
- **Scope**: **PRIVATE BUILD ONLY** (`--dart-define=ENABLE_STREAMING=true`). Never exposed in public portfolio builds.

### Document Schema
| Field Name | Type | Allowed Values / Format |
|---|---|---|
| `match_id` | `number \| string` | Match ID associated with the stream issue |
| `match_title` | `string` | e.g. `"ليفربول vs مانشستر سيتي"` |
| `server_id` | `string` | Server ID being watched (e.g. `"srv_1"`) |
| `server_name` | `string` | Server display name (e.g. `"سيرفر 1 - جودة عالية"`) |
| `issue_type` | `string` | `'buffering'`, `'offline'`, `'wrong_match'`, `'no_audio'`, `'bad_quality'` |
| `user_comment` | `string` | Optional feedback text (max 250 characters) |
| `status` | `string` | Fixed to `'pending'` on creation |
| `user_id` | `string` | Firebase Auth UID (`request.auth.uid`) |
| `created_at` | `Timestamp` | `FieldValue.serverTimestamp()` |

### Client Permissions:
- **Create**: Signed-in users only (`request.auth != null`). `user_id == request.auth.uid`, `status == 'pending'`, and `issue_type` within the 5 allowed enums.
- **Read / Update / Delete**: `false` for clients (`isAdmin()` only).

---

## 5. Poster Generator & Deep-Link Ingestion

- **Android `applicationId`**: `com.livepulse.scores` (verified in `android/app/build.gradle.kts:22`)
- **Supported Schemes**:
  1. Custom Scheme: `shootlive://match/{id}`
  2. Universal Link / App Link: `https://shootlive.app/match/{id}`

### Deep Link Handler:
- Located at [`lib/core/routing/deep_link_handler.dart`](file:///D:/My_Project/shoot_live/lib/core/routing/deep_link_handler.dart).
- Routes cold starts and warm incoming intents directly to `/match/:id`.

### `assetlinks.json` Template for `https://shootlive.app/.well-known/assetlinks.json`:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.livepulse.scores",
      "sha256_cert_fingerprints": [
        "PASTE_DEBUG_SHA256_HERE",
        "PASTE_RELEASE_SHA256_HERE"
      ]
    }
  }
]
```

#### How to Retrieve SHA-256 Fingerprints:
1. **Debug Keystore** (local development):
   ```bash
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
2. **Release Keystore** (production):
   - If using Google Play App Signing: open **Google Play Console** -> Select App -> **Test and release** -> **Setup** -> **App integrity** -> **App signing key certificate** -> Copy **SHA-256 fingerprint**.
   - If using local release keystore:
     ```bash
     keytool -list -v -keystore path/to/upload-keystore.jks -alias your-key-alias
     ```

---

## 6. Revised Firestore Security Rules (`firestore.rules`)

```diff
 rules_version = '2';
 
 service cloud.firestore {
   match /databases/{database}/documents {
 
     // Helper function verifying if the authenticated user has explicit administrator privileges.
     // Requires Firebase Custom Claim: { admin: true }
     function isAdmin() {
       return request.auth != null && request.auth.token.admin == true;
     }
 
     // 1. App Remote Settings (AdMob, Version Updates, API Override)
     // - Public read-only for client apps (including anonymous users)
     // - Writes (create/update/delete) allowed ONLY for verified administrators
     match /config/{document=**} {
       allow read: if true;
       allow write: if isAdmin();
     }
 
     // 2. Per-Match Live Stream Configurations
     // - Public read-only for mobile clients
     // - Writes (create/update/delete) allowed ONLY for verified administrators
     match /match_streams/{matchId} {
       allow read: if true;
       allow write: if isAdmin();
     }
 
     // 3. User Personal Data
     // - Authenticated owner read/write
     match /users/{userId} {
       allow read, write: if request.auth != null && request.auth.uid == userId;
     }
+
+    // 4. Match Polls (Server-Side Voting Architecture)
+    // - Public read for all users
+    // - Client writes are strictly IMPOSSIBLE; voting is handled server-side via POST /api/polls/vote
+    // - Writes allowed ONLY for verified administrators
+    match /match_polls/{matchId} {
+      allow read: if true;
+      allow write: if isAdmin();
+
+      // Per-user vote receipt subcollection:
+      // - Authenticated users may ONLY read their own receipt
+      // - Client writes are forbidden (receipts created by server-side admin SDK transaction)
+      match /votes/{userId} {
+        allow read: if request.auth != null && request.auth.uid == userId;
+        allow write: if isAdmin();
+      }
+    }
+
+    // 5. Direct Sponsorship Campaigns
+    // - Public read for client apps to display banners
+    // - Admins have full management control
+    // - Authenticated users may ONLY increment impression_count or click_count by at most 1
+    // - Decrements are strictly forbidden
+    match /sponsorships/{campaignId} {
+      allow read: if true;
+      allow create, delete: if isAdmin();
+      allow update: if isAdmin() || (
+        request.auth != null &&
+        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['impression_count', 'click_count']) &&
+        request.resource.data.impression_count >= resource.data.impression_count &&
+        request.resource.data.click_count >= resource.data.click_count &&
+        ((request.resource.data.impression_count - resource.data.impression_count) + 
+         (request.resource.data.click_count - resource.data.click_count)) <= 1
+      );
+    }
+
+    // 6. Stream Issue Reports (Private Streaming Builds Only)
+    // - Authenticated users can create reports with status 'pending'
+    // - Clients have NO read, update, or delete access (Admin only)
+    match /stream_reports/{reportId} {
+      allow read, update, delete: if isAdmin();
+      allow create: if request.auth != null &&
+        request.resource.data.user_id == request.auth.uid &&
+        request.resource.data.status == 'pending' &&
+        request.resource.data.issue_type in ['buffering', 'offline', 'wrong_match', 'no_audio', 'bad_quality'];
+    }
   }
 }
```

---

## 7. Deployment Commands & Rollback Plan

### Deployment Procedure
> [!CAUTION]
> The AI agent has **NOT** deployed these rules to production. Deploy only after manual review.

Run from `D:\My_Project\shoot_live_dashboard`:
```bash
# Verify selected Firebase project
firebase projects:list

# Deploy security rules only
firebase deploy --only firestore:rules
```

### Rollback Plan
If any client regressions or authorization rejections occur:
1. **Immediate Rollback**:
   Restore the pre-revision `firestore.rules` (which contained only `config`, `match_streams`, and `users`):
   ```bash
   git checkout HEAD~1 firestore.rules
   firebase deploy --only firestore:rules
   ```
2. **Firebase Console Version History**:
   Navigate to **Firebase Console** -> **Firestore Database** -> **Rules** tab -> **Rules history** -> Click on previous release timestamp -> Click **Revert**.
