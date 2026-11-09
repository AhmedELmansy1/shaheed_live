# Test Fixtures & Third-Party Scraped Data Inventory

> [!WARNING]
> The files listed below reside in the private/internal development repository under `test/fixtures/`.
> They contain **unmodified raw responses and scraped HTML snapshots** collected from upstream sports data providers for local contract verification and parser validation.
>
> **THESE FILES MUST NOT BE COMMITTED TO THE PUBLIC GITHUB PORTFOLIO REPOSITORY.**
> In Phase 5 (Public Tree Packaging), they will be replaced with clean, synthetic mock fixtures with fictitious player names, generic IDs, and anonymized domains.

---

## 1. Inventory of Files under `test/fixtures/`

| Filename | Size (bytes) | Type / Source | Content Description | Public Release Action |
|---|---|---|---|---|
| `raw_matches_today.json` | 8,611 | JSON API | Matches list for today | Replace with synthetic mock JSON |
| `raw_match_info_5795507.json` | 258 | JSON API | Match metadata (finished) | Replace with synthetic mock JSON |
| `raw_match_info_5105046.json` | 182 | JSON API | Match metadata (upcoming) | Replace with synthetic mock JSON |
| `raw_statics_match_5795507.json` | 287 | JSON API | Match statistics (finished) | Replace with synthetic mock JSON |
| `raw_statics_match_5105046.json` | 14 | JSON API | Empty statistics (upcoming) | Replace with synthetic mock JSON |
| `raw_matches_event_5795507.json` | 5,282 | JSON API | Timeline events with type 100 & cards | Replace with synthetic mock JSON |
| `raw_matches_event_5105046.json` | 13 | JSON API | Empty events array (upcoming) | Replace with synthetic mock JSON |
| `raw_matches_lineup_5795507.json` | 42,387 | JSON API | Complete lineups with formations | Replace with synthetic mock JSON |
| `raw_matches_lineup_5105046.json` | 19,935 | JSON API | Partial lineups (upcoming) | Replace with synthetic mock JSON |
| `detail_finished_5795507.html` | 312,119 | Scraped HTML | Upstream match details HTML | Exclude from public tree |
| `detail_upcoming_5105046.html` | 136,948 | Scraped HTML | Upstream match details HTML | Exclude from public tree |
| `feed_2026-11-08.html` | 458,241 | Scraped HTML | Upstream feed HTML | Exclude from public tree |
| `feed_2026-11-09.html` | 43,227 | Scraped HTML | Upstream feed HTML | Exclude from public tree |
| `lineup_finished_5795507.json` | 55,765 | Legacy JSON | Legacy parsed lineup | Exclude from public tree |
| `stats_finished_5795507.html` | 16,457 | Scraped HTML | Upstream statistics HTML | Exclude from public tree |
| `stats_upcoming_5105046.html` | 9 | Scraped HTML | Upstream statistics HTML | Exclude from public tree |

---

## 2. Public Tree Synthetic Replacement Plan

1. **Synthetic Schemas**:
   - Create mock JSON files matching the exact shape expected by `EventMapper`, `LineupParser`, and `StaticsParser`.
   - Use dummy team IDs (`1001`, `1002`) and fictitious team titles (`الفريق المضيف`, `الفريق الضيف`).
   - Use placeholder player names (`لاعب أ`, `لاعب ب`, `صانع ألعاب`).
2. **Exclude Raw HTML Dumps**:
   - Remove all `.html` dumps (`detail_*.html`, `feed_*.html`, `stats_*.html`) from the public repo commit.
   - Keep only unit and parser tests that exercise the sanitized JSON fixtures.
3. **Automated Verification**:
   - Ensure `flutter test test/real_fixtures_parser_test.dart` passes identically against the synthetic mock fixtures in the public repo.

