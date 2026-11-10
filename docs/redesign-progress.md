# Modarraj Premium Redesign Progress

## Status
- **Current Phase:** Phase 2 (Home + Match Details Screens & Previews)
- **Previous Phase:** Phase 1 (Midnight Stadium Tokens, Theme Engine, AppNumberFormat, System UI, Contrast & No-Green Security Scanner)

## Phase 0: Design Specification & Baseline
- [x] Create `docs/design-spec.md` with complete token definitions, typography scale, motion tokens, and WCAG AA guidelines.
- [x] Baseline compilation check: `dart analyze lib test` (0 errors).
- [x] Baseline test suite: `flutter test --no-pub` (268 passed).

## Phase 1: Design System & Theme Engine
- [x] `lib/core/theme/app_colors.dart`: Midnight Stadium Dark & Light palettes.
- [x] `lib/core/theme/app_theme.dart`: Full Material 3 theme configuration with custom extensions (`AppThemeColors`).
- [x] `lib/core/utils/app_number_format.dart`: Centralized Latin tabular numerals (`0-9`) for scores, minutes, stats, standings, percentages, and counts.
- [x] Android launcher & notification accents: updated `colors.xml` and `values-night/colors.xml` to `#0A0F1E` and `#3D7BFF`.
- [x] Strict No-Green Ban: verified across all code with static scanner in `test/design_system_contrast_test.dart`.
- [x] Resilient Poll Voting: defensive JSON parsing, 401 retry, 409 already voted, 429 rate limit, 5xx handling, optimistic rollback.

## Phase 2: Home & Match Details Redesign + Goldens/Preview Generation (In Progress)
- [ ] Review & Polish Home Screen layout (collapsing app bar, wordmark logo, day selector, filter chips, pinned favorite matches, league grouping, HeroMatchCard, offline banner, skeletons).
- [ ] Review & Polish Match Details Screen layout (collapsing gradient header with team crests/scores, sticky tab bar with sliding indicator, 6 tabs: Events, Lineup, Stats, Standings, News, Info).
- [ ] Configure `dart_test.yaml` with the `preview` tag (excluded from default `flutter test`).
- [ ] Implement preview generation tests under `test/preview_generation_test.dart` generating PNGs in `docs/design-preview/` at 360x800, pixel ratio 3, with Cairo font:
  - Home: loading, data, live, offline (Light & Dark)
  - Match Details: live, finished, upcoming (Light & Dark, each tab)
  - Leagues, Team selection, Settings (Light & Dark)
- [ ] Inspect generated preview images for alignment, overflow, contrast, spacing, and RTL consistency.
- [ ] Stop and wait for user approval after Phase 2 completion.

## Next Phase
- **Phase 3:** Remaining screens (Leagues, League Details, Favorites, Onboarding/Team Selection, Settings, About Developer, Notification Permission, Force Update) + final motion polish.

## Known Issues / Notes
- None. All 268 tests pass and 0 analysis issues exist.

